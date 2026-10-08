//
//  BreakStartModel.swift
//  Focus Bear
//
//  State behind the SwiftUI break start screen (`BreakStartView`) — the screen shown before a micro
//  break begins. It replaces the micro-break presentation of the storyboard `firstViewController`
//  (its `._MICRO_BREAK_` branch of `viewWillAppear`), keeping what that screen did: the list of break
//  habits, the office / work-from-home segmented control, the Start and Skip controls, and the
//  5-second countdown that starts the break by itself.
//
//  Two things are new: that countdown is now opt-in (`SettingsManagerObject.isBreakAutoStartEnabled`,
//  which the screen's own checkbox drives), and there is a brain-dump box beside the list that writes
//  through the same `PUT /note` upsert the Notes screen uses, so a thought parked before a break is
//  the same note the dashboard and mobile show.
//

import AppKit

/// User-facing strings, config-driven (`configjson`) like every other screen. Spanish lives in the
/// assets repo config-es.json.
struct BreakStartStrings {
    var chairExercises = "🪑 Chair exercises"
    var fullMovement = "🙆‍♂️ Full movement exercises"
    var autoStartCheckbox = "Start break habits automatically next time"
    var brainDumpHint = "Park a thought here so you can let it go for the break — it saves to your brain dump."
    var skipBreak = "Skip this habit for today"
    var chairExercisesTooltip = "When you're working from the office, I will only give you appropriate break activities (e.g. chair stretches rather than pushups)."
    var fullMovementTooltip = "No-one's around! You can do break activities that are a bit more fun, e.g. Dance like no-one's watching"

    static func load() -> BreakStartStrings {
        var strings = BreakStartStrings()
        if let info = configjson.value(forKey: "activityInfo") as? NSDictionary {
            func read(_ key: String, _ target: inout String) {
                if let value = info.value(forKey: key) as? String, !value.isEmpty { target = value }
            }
            read("breakModeChairExercisesText", &strings.chairExercises)
            read("breakModeFullMovementText", &strings.fullMovement)
            read("breakAutoStartCheckboxText", &strings.autoStartCheckbox)
            read("breakBrainDumpHintText", &strings.brainDumpHint)
            read("buttonSkipHabitText", &strings.skipBreak)
        }
        // The two mode tooltips already exist (and are translated) for the segmented control this
        // screen replaces — reuse them rather than adding near-duplicates.
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary {
            if let value = menuInfo.value(forKey: "toolTipOfficeMode") as? String, !value.isEmpty {
                strings.chairExercisesTooltip = value
            }
            if let value = menuInfo.value(forKey: "toolTipWfhMode") as? String, !value.isEmpty {
                strings.fullMovementTooltip = value
            }
        }
        return strings
    }
}

/// One row of the break-habit list.
struct BreakHabitRow: Identifiable {
    let id: Int
    let text: String
}

final class BreakStartModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var title = ""
    @Published private(set) var progressText = ""
    @Published private(set) var startButtonTitle = ""
    @Published private(set) var habits: [BreakHabitRow] = []
    @Published private(set) var mode: BreakStartKit.BreakMode = .fullMovement
    @Published private(set) var countdownText = ""
    @Published private(set) var isCountingDown = false
    @Published var isAutoStartEnabled = SettingsManagerObject.isBreakAutoStartEnabled

    let strings = BreakStartStrings.load()
    /// The brain dump is the user's real brain-dump note, loaded and saved through the same store the
    /// Notes screen uses — not a second, break-only scratchpad.
    let notesStore = NotesStore(strings: NotesStrings.load())

    /// Asked before switching to office mode when nothing is office-friendly; the host puts up the
    /// app's existing "shall I add one?" alert. Answering true means the mode switch may proceed.
    var confirmOfficeModeWithNoActivities: ((@escaping (Bool) -> Void) -> Void)?
    /// Shows the one-time "ok, office-appropriate activities only" confirmation the old screen showed.
    var announceOfficeModeEnabled: (() -> Void)?

    private var timer: Timer?
    private var remainingSeconds = 0

    // MARK: - Appearing

    /// Rebuild from the live break state and arm the countdown if the person opted into auto-start.
    func screenAppeared() {
        isAutoStartEnabled = SettingsManagerObject.isBreakAutoStartEnabled
        mode = BreakStartKit.BreakMode.from(isOfficeModeEnabled: SettingsManagerObject.isOfficeModeEnabled)
        refreshFromBreakState()
        notesStore.screenAppeared()

        let decision = BreakStartKit.startDecision(autoStartEnabled: SettingsManagerObject.isBreakAutoStartEnabled)
        if decision.runsCountdown {
            addLog(text: "break start: auto-start is on — counting down")
            beginCountdown()
        } else {
            addLog(text: "break start: auto-start is off — waiting for the user to press Start")
            stopCountdown()
        }
    }

    func screenDisappeared() {
        stopCountdown()
        notesStore.screenDisappeared()
    }

    /// Title, duration line, Start-button title and the habit list, all read from the same places the
    /// storyboard screen read them: `activityCompletionVc` (which builds the break's copy in
    /// `startBreakActivity()`) and `arrFinalBreakActivities`.
    func refreshFromBreakState() {
        habits = BreakStartModel.habitRows()
        title = BreakStartModel.breakTitle()
        progressText = activityCompletionVcObj?.lblProgress.stringValue ?? ""
        startButtonTitle = activityCompletionVcObj?.btnMain.title ?? ""
    }

    private static func habitRows() -> [BreakHabitRow] {
        arrFinalBreakActivities.enumerated().compactMap { index, filtered in
            guard let activity = filtered.activity else { return nil }
            let name = filtered.randomChoice?.name ?? activity.name ?? ""
            let duration = activity.durationSeconds ?? 0
            let text = activity.useTimer
                ? "\(index + 1).   \(name) - \(getStringTime(seconds: duration))"
                : "\(index + 1).   \(name)"
            return BreakHabitRow(id: index, text: text)
        }
    }

    /// `activityCompletionVc` owns the break's title, but it can still be empty the first time the
    /// list renders (it is only populated once the break screen is built), so fall back to computing
    /// it from the first activity — the same fallback the storyboard screen carried.
    private static func breakTitle() -> String {
        let existing = activityCompletionVcObj?.lblTitle.stringValue ?? ""
        guard existing.isEmpty else { return existing }
        guard let first = arrFinalBreakActivities.first, let activity = first.activity else { return "" }
        let name = activity.choiceType != ._RANDOM_ ? (activity.name ?? "") : (first.randomChoice?.name ?? "")
        return getStartBreakActivityTitleText(seconds: activity.durationSeconds, activityName: name)
    }

    // MARK: - Countdown

    private func beginCountdown() {
        stopCountdown()
        remainingSeconds = BreakStartKit.autoStartCountdownSeconds
        countdownText = BreakStartKit.countdownText(remainingSeconds: remainingSeconds)
        isCountingDown = true
        DispatchQueue.main.async {
            let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }

    func stopCountdown() {
        timer?.invalidate()
        timer = nil
        isCountingDown = false
    }

    @objc private func tick() {
        remainingSeconds -= 1
        countdownText = BreakStartKit.countdownText(remainingSeconds: remainingSeconds)
        guard remainingSeconds <= 0 else { return }
        stopCountdown()
        addLog(text: "break start: countdown finished — starting the break")
        start()
    }

    // MARK: - Actions

    /// Start the break. Goes through `activityCompletionVc.btnMainClicked` exactly as the storyboard
    /// screen's Start button did, so the whole downstream break flow is untouched.
    func start() {
        addLog(text: "[user-action] break start: Start clicked")
        stopCountdown()
        notesStore.flushPendingSaves()
        activityCompletionVcObj?.btnMainClicked(self)
    }

    /// Skip / postpone the break — the same handler the old screen's postpone button called.
    func skip() {
        addLog(text: "[user-action] break start: Skip clicked")
        stopCountdown()
        notesStore.flushPendingSaves()
        activityCompletionVcObj?.btnSkipHabitClicked(self)
    }

    /// The "Start break habits automatically next time" checkbox. It is the same preference as the
    /// Settings > Micro Breaks toggle, so setting it here syncs the same way.
    func setAutoStart(_ enabled: Bool) {
        guard enabled != SettingsManagerObject.isBreakAutoStartEnabled else { return }
        addLog(text: "[user-action] break start: auto-start set to \(enabled)")
        SettingsManagerObject.isBreakAutoStartEnabled = enabled
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        allApiObject.capturePosthog(event: enabled ? "settings-changed-enable-break-auto-start"
                                                   : "settings-changed-disable-break-auto-start", metadata: [:])
        isAutoStartEnabled = enabled
        // Ticking the box mid-screen shouldn't hijack the break the person is looking at; it takes
        // effect from the next one, which is what the label promises.
    }

    // MARK: - Office / work-from-home mode

    func selectMode(_ newMode: BreakStartKit.BreakMode) {
        guard newMode != mode else { return }
        addLog(text: "[user-action] break start: mode set to \(newMode)")
        guard newMode.isOfficeMode else {
            applyOfficeMode(false)
            return
        }
        guard BreakStartKit.canEnterOfficeMode(from: arrAllbreakActivities) else {
            // Nothing office-friendly to do: the app offers to add a stand-and-stretch activity first.
            confirmOfficeModeWithNoActivities? { [weak self] shouldSwitch in
                guard let self = self else { return }
                if shouldSwitch {
                    self.applyOfficeMode(true)
                } else {
                    self.mode = BreakStartKit.BreakMode.from(isOfficeModeEnabled: SettingsManagerObject.isOfficeModeEnabled)
                }
            }
            return
        }
        applyOfficeMode(true)
    }

    /// Performs the real switch, step for step as `firstViewController.enableOfficeMode()` /
    /// `segmentControlOfficeModeClicked` did: persist and sync the setting, swap the menu-bar and dock
    /// icons, rebuild the break's activity list for the new mode, and refresh the copy that depends
    /// on it.
    private func applyOfficeMode(_ enabled: Bool) {
        if enabled { announceOfficeModeEnabled?() }
        SettingsManagerObject.isOfficeModeEnabled = enabled
        allApiObject.capturePosthog(event: enabled ? "enable-office-mode" : "disable-office-mode", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name(enabled ? "Bear-Office-Small" : "Bear-Small"))
        NSApplication.shared.applicationIconImage = enabled ? NSImage(named: NSImage.Name("Bear-Office-icon")) : nil

        getHabitsVcObject().reFillBreakActivitiesArray()
        // reFillBreakActivitiesArray turns office mode back off when it finds nothing office-friendly,
        // so read the setting back rather than trusting what we just asked for.
        mode = BreakStartKit.BreakMode.from(isOfficeModeEnabled: SettingsManagerObject.isOfficeModeEnabled)
        activityCompletionVcObj?.startBreakActivity()
        refreshFromBreakState()
    }
}
