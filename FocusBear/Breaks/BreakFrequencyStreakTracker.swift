//
//  BreakFrequencyStreakTracker.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-05-08.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Tracks consecutive days on which the user turns breaks off for the day.
//  After 2 consecutive days, triggers the break-frequency prompt (#1144).
//
//  How it works:
//  • recordBreaksOffForToday() — call from deactivateBreaksVc when the user
//    taps "Turn them off for today".  It appends today's date to the persisted
//    streak array, then checks whether we have ≥2 consecutive days.
//  • shouldShowPrompt() — returns true when the consecutive streak is met AND
//    the prompt hasn't been shown for the current streak yet.
//  • markPromptShown() — call after showing the dialog to prevent repeats.
//  • resetStreak() — call on days the user does NOT turn off breaks.
//  • saveNewBreakFrequency(_:) — persists the chosen new frequency to
//    UserDefaults so the timer picks it up on the next cycle.
//

import Foundation

final class BreakFrequencyStreakTracker {

    // MARK: - Singleton
    static let shared = BreakFrequencyStreakTracker()

    // MARK: - UserDefaults keys
    private let kBreakOffDates          = "kFBBreakOffDates"          // [String] — "yyyy-MM-dd"
    private let kBreakOffPromptShown    = "kFBBreakOffPromptShownDate" // String — last date prompt was shown
    private let kBreakFrequencyMinutes  = "kFBBreakFrequencyMinutes"   // Int — overridden frequency

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        return df
    }()

    private init() {}

    // MARK: - Public API

    /// Call whenever the user taps "Turn breaks off for today".
    /// Persists today's date, culls old entries, then triggers the prompt if threshold met.
    func recordBreaksOffForToday() {
        let today = todayString()
        var dates = loadBreakOffDates()

        // Avoid duplicate entries for the same day
        guard !dates.contains(today) else {
            addLog(text: "BreakFrequencyStreakTracker: already recorded break-off for \(today)")
            checkAndShowPromptIfNeeded()
            return
        }

        dates.append(today)
        // Keep only the last 7 days to avoid unbounded growth
        if dates.count > 7 {
            dates = Array(dates.suffix(7))
        }
        saveBreakOffDates(dates)
        addLog(text: "BreakFrequencyStreakTracker: recorded break-off for \(today) — streak array: \(dates)")

        checkAndShowPromptIfNeeded()
    }

    /// Returns true if the current streak is ≥2 consecutive days AND the prompt
    /// hasn't been shown for this streak yet.
    func shouldShowPrompt() -> Bool {
        let streak = consecutiveStreak()
        addLog(text: "BreakFrequencyStreakTracker.shouldShowPrompt — streak=\(streak)")
        guard streak >= 2 else { return false }

        // Don't re-show if we already showed it during this streak
        let today = todayString()
        let lastShownDate = UserDefaults.standard.string(forKey: kBreakOffPromptShown)
        guard lastShownDate != today else {
            addLog(text: "BreakFrequencyStreakTracker: prompt already shown today (\(today))")
            return false
        }
        return true
    }

    /// Call after showing the prompt so it isn't repeated today.
    func markPromptShown() {
        UserDefaults.standard.set(todayString(), forKey: kBreakOffPromptShown)
        addLog(text: "BreakFrequencyStreakTracker: marked prompt shown for \(todayString())")
    }

    /// Call on days where the user does NOT turn off breaks, to reset the streak.
    func resetStreak() {
        saveBreakOffDates([])
        addLog(text: "BreakFrequencyStreakTracker: streak reset")
    }

    /// Persist the new break frequency and reload it for the break timer.
    func saveNewBreakFrequency(_ minutes: Int) {
        UserDefaults.standard.set(minutes, forKey: kBreakFrequencyMinutes)
        // Update the live global used by the break timer
        breakAfterMinutes = minutes
        addLog(text: "BreakFrequencyStreakTracker: new break frequency saved — \(minutes) min")
        // Restart the break timer so the new frequency takes effect immediately
        DispatchQueue.main.async {
            if getHabitsVcObject().breakTimer != nil {
                getHabitsVcObject().setActivityTimer()
            }
        }
    }

    // MARK: - Private helpers

    private func checkAndShowPromptIfNeeded() {
        guard shouldShowPrompt() else { return }
        DispatchQueue.main.async {
            BreakFrequencyPromptVc.showIfNeeded()
        }
    }

    /// Count how many trailing consecutive calendar days are in the break-off array.
    func consecutiveStreak() -> Int {
        let dates = loadBreakOffDates().compactMap { dateFormatter.date(from: $0) }.sorted()
        guard !dates.isEmpty else { return 0 }

        var streak = 1
        let cal = Calendar.current

        // Walk backwards from the most recent entry
        for i in stride(from: dates.count - 1, through: 1, by: -1) {
            let diff = cal.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            if diff == 1 {
                streak += 1
            } else {
                break
            }
        }

        // The streak must include today or yesterday to be "active"
        let today = dateFormatter.date(from: todayString())!
        guard let last = dates.last else { return 0 }
        let daysAgo = cal.dateComponents([.day], from: last, to: today).day ?? 99
        if daysAgo > 1 { return 0 }  // streak is stale

        return streak
    }

    // MARK: - Persistence helpers

    private func loadBreakOffDates() -> [String] {
        return UserDefaults.standard.stringArray(forKey: kBreakOffDates) ?? []
    }

    private func saveBreakOffDates(_ dates: [String]) {
        UserDefaults.standard.set(dates, forKey: kBreakOffDates)
    }

    private func todayString() -> String {
        return dateFormatter.string(from: Date())
    }
}
