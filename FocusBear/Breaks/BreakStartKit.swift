//
//  BreakStartKit.swift
//  Focus Bear
//
//  Pure, AppKit-free logic behind the break start screen (`BreakStartView`) — the screen shown before
//  a micro break begins, listing the break habits with the office / work-from-home toggle. Everything
//  here is a function of its arguments, so it can be unit-tested (`BreakStartKitTests`) without
//  standing up the app.
//

import Foundation

enum BreakStartKit {

    /// How long the screen counts down before starting by itself. Unchanged from the countdown
    /// `firstViewController.startMicroBreakTimer(duration: 5)` has always run on this screen — only
    /// *whether* it runs is new.
    static let autoStartCountdownSeconds = 5

    // MARK: - Auto-start

    /// What happens when the break start screen appears.
    struct StartDecision: Equatable {
        /// The 5-second countdown runs and then starts the break without the person pressing anything.
        let runsCountdown: Bool
    }

    /// Auto-start is opt-in. With the preference off — the default — the screen waits for the Start
    /// button instead of counting itself down, so a break can't carry someone off mid-thought.
    static func startDecision(autoStartEnabled: Bool) -> StartDecision {
        StartDecision(runsCountdown: autoStartEnabled)
    }

    // MARK: - Countdown

    /// The countdown label: "MM:SS", matching the format the screen has always shown. Negative
    /// remainders clamp to zero so an overrun never renders "-0:01".
    static func countdownText(remainingSeconds: Int) -> String {
        let remaining = max(remainingSeconds, 0)
        let minutes = remaining / 60
        let seconds = remaining % 60
        let twoDigits = { (value: Int) -> String in value < 10 ? "0\(value)" : "\(value)" }
        return "\(twoDigits(minutes)):\(twoDigits(seconds))"
    }

    // MARK: - Where a break ends

    /// Where the user lands once a break is over (finished or skipped through).
    enum BreakEndDestination: Equatable {
        /// A focus session is still theirs — go back to it.
        case focusSession
        /// No session: the same place breaks landed before sessions were part of the picture.
        case suggestFocusSession
    }

    /// A break interrupts whatever the person was doing; ending it should hand them back, not dump
    /// them somewhere else. If a session is still running — or paused, which is still their session
    /// to resume — that is where they belong. With no session, nothing has been interrupted, so keep
    /// the long-standing behaviour of offering to start one.
    static func destinationAfterBreak(isFocusSessionActive: Bool) -> BreakEndDestination {
        isFocusSessionActive ? .focusSession : .suggestFocusSession
    }

    // MARK: - Office / work-from-home mode

    /// The two modes the screen toggles between. This is a presentation of the app's existing
    /// `SettingsManagerObject.isOfficeModeEnabled` setting, not a second one: `.chairExercises` *is*
    /// office mode, `.fullMovement` *is* work-from-home.
    enum BreakMode: Equatable {
        case chairExercises
        case fullMovement

        var isOfficeMode: Bool { self == .chairExercises }

        var opposite: BreakMode { isOfficeMode ? .fullMovement : .chairExercises }

        var profileName: String { isOfficeMode ? "office" : "wfh" }

        static func from(isOfficeModeEnabled: Bool) -> BreakMode {
            isOfficeModeEnabled ? .chairExercises : .fullMovement
        }
    }

    /// Which break activities a mode offers. Office mode shows only the office-friendly ones (chair
    /// stretches rather than pushups); work-from-home shows everything. Mirrors the filter
    /// `habitsVc.reFillBreakActivitiesArray()` applies when it rebuilds the break for a mode.
    static func activities(from all: [breakActivity], mode: BreakMode) -> [breakActivity] {
        guard mode.isOfficeMode else { return all }
        return all.filter { $0.isOfficeFriendly }
    }

    /// Switching to office mode is only offered when there is something to do in it. When no activity
    /// is office-friendly the screen must ask before switching (the app offers to add a stand-and-
    /// stretch activity) rather than leaving the person with an empty break.
    static func canEnterOfficeMode(from all: [breakActivity]) -> Bool {
        all.contains { $0.isOfficeFriendly }
    }

    static func unplayedActivities(from all: [breakActivity], excludingIDs: Set<String>) -> [breakActivity] {
        // Once an unidentified activity has played, conservatively exclude other unidentified
        // entries too: treating nil IDs as distinct could replay that same activity.
        all.filter { !excludingIDs.contains($0.id ?? "") }
    }

    /// A mode switch only replaces the not-yet-started suffix. Completion and quantity logging
    /// still address the original current index, including its original random choice.
    static func replacingUpcomingActivities(in existing: [breakActivityFilter], currentIndex: Int,
                                           selected: [breakActivityFilter], totalLimit: Int? = nil) -> [breakActivityFilter]? {
        guard existing.indices.contains(currentIndex), existing[currentIndex].activity != nil else { return nil }
        let prefix = Array(existing.prefix(currentIndex + 1))
        let playedIDs = Set(prefix.map { $0.activity?.id ?? "" })
        let upcoming = selected.filter { entry in
            guard let activity = entry.activity else { return false }
            return !playedIDs.contains(activity.id ?? "")
        }
        let remainingLimit = totalLimit.map { max(0, $0 - prefix.count) } ?? upcoming.count
        return prefix + Array(upcoming.prefix(remainingLimit))
    }
}
