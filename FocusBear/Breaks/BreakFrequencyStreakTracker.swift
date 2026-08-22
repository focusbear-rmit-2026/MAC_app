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
    // Use the GLOBAL keys (allUserdefaults.swift), which get the userId appended on login (AppDelegate),
    // so each account's off-streak / frequency is separate on a shared device. Computed (not stored) so
    // they read the current per-user value — this singleton can be created before the login-keying runs.
    private var kBreakOffDates: String          { kUserdefaultsBreakOffDates }         // [String] — "yyyy-MM-dd"
    private var kBreakOffPromptShown: String    { kUserdefaultsBreakOffPromptShown }   // String — last date prompt shown

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
        addLog(text: "BreakFrequencyStreakTracker: recorded break-off for \(today) — streak length: \(dates.count)")

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

    /// Persist the new break frequency, sync it to the server, and reload it for the break timer.
    func saveNewBreakFrequency(_ minutes: Int) {
        // Update the live global used by the break timer. The value is persisted only to
        // break_after_minutes (server + cached settings blob below) — the single source of truth — so we
        // never keep a separate local frequency key that would shadow the server value on the next read.
        breakAfterMinutes = minutes
        addLog(text: "BreakFrequencyStreakTracker: new break frequency saved — \(minutes) min")

        // Sync to server — same pattern used by shutOffTimeVc / editHabitRoutineVc:
        // load the cached settings blob, mutate the one field, PUT via isSettingsValid,
        // then re-cache whatever the server returns.
        var jsonResult = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String,
            let data = stringDic.data(using: .utf8) {
            do {
                jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? NSDictionary()
            } catch {
                addLog(text: "BreakFrequencyStreakTracker: failed to parse cached settings JSON — \(error.localizedDescription)")
            }
        }

        if let mutableDic = jsonResult.mutableCopy() as? NSMutableDictionary {
            mutableDic["break_after_minutes"] = minutes
            allApiObject.isSettingsValid(settings: mutableDic, isOnboarding: false, completionHandler: { dic, statusCode in
                if statusCode == 200, let dic = dic {
                    addLog(text: "BreakFrequencyStreakTracker: break_after_minutes synced to server — \(minutes) min")
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
                        if let backToString = String(data: jsonData, encoding: .utf8) {
                            UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                        }
                    } catch {
                        addLog(text: "BreakFrequencyStreakTracker: failed to re-cache settings JSON — \(error.localizedDescription)")
                    }
                } else {
                    addLog(text: "BreakFrequencyStreakTracker: server sync failed — statusCode \(statusCode)")
                }
            })
        } else {
            addLog(text: "BreakFrequencyStreakTracker: no cached settings JSON found — could not sync break_after_minutes to server")
        }

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
