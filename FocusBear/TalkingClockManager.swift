//
//  TalkingClockManager.swift
//  Focus Bear
//
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class TalkingClockManager {
    static let shared = TalkingClockManager()
    private var timer: Timer?
    private var isAnnouncing = false

    private init() {}

    func start() {
        stop()
        guard SettingsManagerObject.isTalkingClockEnabled else { return }
        scheduleNextAnnouncement()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        // Only restart if the timer actually died (e.g. it was never started or
        // was invalidated). If it is still alive, leave the existing phase intact
        // so a system wake does not reset the announcement schedule.
        guard SettingsManagerObject.isTalkingClockEnabled else {
            stop()
            return
        }
        if timer == nil || !(timer?.isValid ?? false) {
            start()
        }
    }

    // Self-rescheduling one-shot timer (rather than a single repeating timer) so every
    // announcement re-aligns to the wall clock. A repeating timer would just fire N
    // minutes after whenever start()/restart() happened to run (e.g. app launch), not
    // on the quarter-hour a user picking "every 15 min" would expect.
    private func scheduleNextAnnouncement() {
        guard SettingsManagerObject.isTalkingClockEnabled else { return }
        let delay = secondsUntilNextBoundary()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.announceTime()
            self?.scheduleNextAnnouncement()
        }
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    /// Seconds until the next wall-clock boundary aligned to the configured interval,
    /// e.g. 15 min -> :00/:15/:30/:45, 60 min -> the top of the next hour.
    private func secondsUntilNextBoundary() -> TimeInterval {
        let intervalMinutes = max(SettingsManagerObject.talkingClockIntervalMinutes, 1)
        let calendar = Calendar.current
        let now = Date()
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        let nanosecond = calendar.component(.nanosecond, from: now)
        let minutesToNextBoundary = intervalMinutes - (minute % intervalMinutes)
        let secondsIntoCurrentMinute = Double(second) + Double(nanosecond) / 1_000_000_000
        return max(Double(minutesToNextBoundary * 60) - secondsIntoCurrentMinute, 1)
    }

    @objc func announceTime() {
        guard SettingsManagerObject.isTalkingClockEnabled else {
            stop()
            return
        }
        guard !isInQuietHours() else { return }
        guard !shouldSuppressForMeeting() else { return }

        // Guard against overlapping announcements stacking up if a previous
        // `say` is still running (e.g. very short intervals or a slow system).
        guard !isAnnouncing else { return }

        // Round to the nearest 15 minutes so the clock says "6:45", not "6:44".
        let now = Date()
        let calendar = Calendar.current
        let minutesIntoDay = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let roundedMinutes = Int((Double(minutesIntoDay) / 15.0).rounded()) * 15
        let roundedTime = calendar.startOfDay(for: now).addingTimeInterval(Double(roundedMinutes) * 60)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: roundedTime)
        let text = "The time is now \(timeString)"

        isAnnouncing = true
        // Run on a background queue because `shell()` blocks until the command
        // completes; we don't want to stall the main run loop while `say` speaks.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            shell(launchPath: "/usr/bin/say", arguments: [text])
            DispatchQueue.main.async {
                self?.isAnnouncing = false
            }
        }
    }

    private func isInQuietHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let quietStart = SettingsManagerObject.talkingClockQuietStartHour * 60
            + SettingsManagerObject.talkingClockQuietStartMinute
        let quietEnd = SettingsManagerObject.talkingClockQuietEndHour * 60
            + SettingsManagerObject.talkingClockQuietEndMinute

        if quietStart <= quietEnd {
            return currentMinutes >= quietStart && currentMinutes < quietEnd
        } else {
            return currentMinutes >= quietStart || currentMinutes < quietEnd
        }
    }

    private func shouldSuppressForMeeting() -> Bool {
        TalkingClockMeetingGate.shouldSuppress(
            isSuppressionEnabled: SettingsManagerObject.talkingClockSuppressDuringMeetings,
            isUserOnMeeting: appdelegate?.isUserOnMeeting ?? false,
            isMeetingSessionLive: currentAccountabilityBuddySession?.isMeeting == true,
            hasLiveOrImminentAnnouncedMeeting: MeetingCoverage.hasLiveOrImminentMeeting(
                now: Date(), meetings: AnnouncedMeetingRegister.shared.activeMeetings()))
    }
}

/// When the talking clock stays silent for a meeting.
///
/// Live detection alone was not enough. Report 2026-10-06_13-30-40: the clock spoke at 13:30 and
/// 16:30, at the start of meetings Late No More had announced two minutes earlier, with a meeting
/// focus session already running. At 13:30 the Teams web call was not detected (mic owner
/// "Unknown"); at 16:30 the Meet tab was opened seconds after the announcement. Meetings start on
/// the same boundaries the clock speaks on, so the calendar and the meeting session count too.
enum TalkingClockMeetingGate {
    /// - Parameters:
    ///   - isUserOnMeeting: live mic/camera/browser detection (`handleMeetingDetected`). It works
    ///     without any focus block, unlike `currentRunningFocusType["isMeetings"]`.
    ///   - isMeetingSessionLive: a meeting focus session (started from a Late No More announcement).
    ///   - hasLiveOrImminentAnnouncedMeeting: an announced meeting is running or starts within
    ///     `MeetingPostponeRules.imminentMeetingLeadSeconds`.
    static func shouldSuppress(isSuppressionEnabled: Bool,
                               isUserOnMeeting: Bool,
                               isMeetingSessionLive: Bool,
                               hasLiveOrImminentAnnouncedMeeting: Bool) -> Bool {
        guard isSuppressionEnabled else { return false }
        return isUserOnMeeting || isMeetingSessionLive || hasLiveOrImminentAnnouncedMeeting
    }
}
