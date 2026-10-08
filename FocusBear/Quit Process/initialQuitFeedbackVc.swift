//
//  initialQuitFeedbackVC.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 30/09/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import Foundation
import SwiftUI

// The quit popup. Rebuilt in SwiftUI as a two-step, non-guilt-trippy flow:
//   Step 1 — ask WHY: "did something go wrong, or are you just turning Focus Bear off for a bit?"
//     • "The app is broken/annoying" → routes into the existing quit-reason capture (reimplemented in
//       SwiftUI here) → records the reason + feedback and quits.
//     • "Just turning it off" → Step 2.
//   Step 2 — "turn it off completely, or just pause distraction blocking for a bit?"
//     • "Turn it off until tomorrow" → disable the app until tomorrow morning (reuses the existing
//       `kUserdefaults4HourReActivateTime` deactivate-for-a-duration mechanism).
//     • "Pause blocking for N hr" (+/- stepper, matches the menu's focus-session duration control) →
//       disable the app for N hours via the same mechanism.
class initialQuitFeedbackVc: NSViewController {

    var enterPasswordVcObj: enterPasswordVc?

    // Transient view state kept off SwiftUI @State so a reopen of this reused-singleton VC starts fresh
    // (#2584); reset in resetData().
    private let quitModel = QuitPopupModel()

    override func loadView() {
        let root = QuitPopupView(
            strings: QuitPopupStrings.load(),
            model: quitModel,
            onCancel: { [weak self] in self?.view.window?.close() },
            onReportBug: { [weak self] in self?.openReportProblem() },
            onQuitBroken: { [weak self] reason, feedback in
                self?.quitBroken(reason: reason, feedback: feedback)
            },
            onOffUntilTomorrow: { [weak self] in self?.turnOffUntilTomorrow() },
            onSnoozeFeatures: { [weak self] features, hours in
                self?.snoozeFeatures(features, hours: hours)
            })
        // Wrap the SwiftUI hosting view in a plain container rather than making it the content view
        // directly: when NSHostingView IS the titled window's content view, AppKit applies the title-bar
        // safe-area inset to it and pushes the SwiftUI content down, leaving a gap below the title bar.
        // Pinning it inside a plain NSView defeats that, so the content fills flush to the top.
        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view = NSView(frame: NSRect(x: 0, y: 0, width: QuitPopupLayout.width, height: QuitPopupLayout.height))
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: Report a bug → existing in-app "Report Problem" flow

    /// Open the app's existing Report Problem UI (the `helpVc` "Report Problem" tab) rather than building a
    /// new reporting path. Closes the quit popup, makes the main window visible, selects Help & Support in
    /// the left menu, then switches to the Report Problem tab.
    private func openReportProblem() {
        addLog(text: "[user-action] quit popup - report a bug")
        allApiObject.capturePosthog(event: QuitPopupAnalytics.reportBug, metadata: [:])
        view.window?.close()
        if !(mainWindowControllerObj?.window?.isVisible ?? false) {
            mainWindowControllerObj?.showWindow(self)
        }
        leftMenuVcObj?.showHelpAndSupportView()
        let help = getHelpVcObject()
        if let reportTab = help.tabViewReportProblem {
            help.tabView?.selectTabViewItem(reportTab)
        }
    }

    // MARK: Pause selected features for a duration (auto-resume)

    /// Temporarily pause the chosen features via `FeatureSnooze` — the app keeps running and each feature
    /// switches itself back on once the window passes (no restart, unlike the whole-app deactivate path).
    private func snoozeFeatures(_ features: Set<SnoozableFeature>, hours: Int) {
        guard !features.isEmpty else { return }
        let until = Date().addingTimeInterval(TimeInterval(hours * 3600))
        for feature in features { FeatureSnooze.snooze(feature, until: until) }
        let labels = features.map { $0.rawValue }.sorted().joined(separator: ",")
        addLog(text: "[user-action] quit popup - paused [\(labels)] for \(hours)hr")
        allApiObject.capturePosthog(event: QuitPopupAnalytics.snoozeFeatures,
                                    metadata: ["hours": hours, "features": labels])
        view.window?.close()
    }

    // MARK: Step 1 (broken) → existing quit behaviour

    /// Record the quit reason (+ optional feedback) and quit after a short beat so the analytics send has
    /// time to flush — mirrors the legacy 1-second loader. Fires the historic `app-quit` event so existing
    /// dashboards keep working, plus the new intent event.
    private func quitBroken(reason: String, feedback: String) {
        addLog(text: "[user-action] quit popup - broken/annoying quit (\(reason))")
        allApiObject.capturePosthog(event: QuitPopupAnalytics.reasonBroken, metadata: ["quitReason": reason])
        allApiObject.capturePosthog(event: QuitPopupAnalytics.appQuit, metadata: [
            "quitReason": reason,
            "usageStartDate": getFirstRunDateString(),
            "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled(),
            "feedback": feedback,
        ])
        SensitiveDefaults.set(reason, forKey: kUserDefaultsLastQuitReason)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            appdelegate?.quitAppForUser()
        }
    }

    // MARK: Step 2 (just turning off) → deactivate for a duration

    /// Turn the app off until tomorrow morning. Quits the app (kept quit — see deactivateApp) and asks the
    /// always-running helper to relaunch it at `target`; the reactivate time re-enables it on that launch.
    private func turnOffUntilTomorrow() {
        // #2575: come back tomorrow at the user's Focus Bear start time. The always-running helper relaunches
        // the app at this time (and re-enables it via the reactivate check on that launch).
        let target = QuitPopupSchedule.tomorrowAtStartTime()
        addLog(text: "[user-action] quit popup - turn off until tomorrow (\(target))")
        allApiObject.capturePosthog(event: QuitPopupAnalytics.offUntilTomorrow, metadata: [:])
        deactivateApp(until: target, abortReason: "Turned off until tomorrow")
    }

    private func deactivateApp(until date: Date, abortReason: String) {
        addLog(text: "App turned off until \(date) - \(abortReason)")
        addEntryInStatsCsv(logType: "quit abort", activity: "quit", durationInSeconds: "",
                           quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "",
                           distractionsEncountered: "", abortReason: abortReason, feedback: "", tags: "")
        // #2575: "turn everything off until tomorrow" simply QUITS the app and asks the always-running
        // helper to relaunch it at `date` (see scheduleMainAppRestart / FBHelper — no new LaunchAgent).
        // We deliberately do NOT persist any disabled state (no isAppEnabled=false / reactivate-time /
        // abort-date writes): while the app is quit it does nothing, so it is already "off", and if the
        // user reopens it before `date` it should just work normally — the scheduled-restart request is
        // cleared on the next launch (applicationDidFinishLaunching). A short beat lets posthog flush, then
        // quit the same way as menuItem_Quit(): stop the force-quit monitor so the helper doesn't relaunch
        // us in 10s, mark the terminate self-initiated (so it isn't gated by the quit password flow), and
        // terminate without an immediate relaunch.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            scheduleMainAppRestart(at: date)
            stopMainAppForceQuitMonitoring()
            appdelegate?.terminateFromSelf = true
            quitApplicationSmoothly()
        }
    }

    // MARK: Password gate (unchanged behaviour)

    /// Overlay the password gate when quitting requires it. Called from `showQuittingConfirmView` after the
    /// content is set. Once passed, `enterPasswordVc` removes the overlay (see enterPasswordVc.swift), and
    /// every action in the new flow sits behind it.
    func resetData() {
        // #2584: this VC is a reused singleton, so the SwiftUI view's transient state survives a
        // close/reopen. Clear the busy/loader state here — before the guard below, which returns early
        // when the password gate isn't needed — so every open starts interactive instead of coming back
        // with everything disabled and the spinner stuck.
        quitModel.isBusy = false
        guard shouldAskPassword(), SettingsManagerObject.isPasswordRequireInQuitApp else { return }
        if enterPasswordVcObj == nil {
            enterPasswordVcObj = mainStoryboard.instantiateController(
                withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
        }
        guard let pwView = enterPasswordVcObj?.view else { return }
        view.addSubview(pwView)
        view.addConstraints(subView: pwView)
        enterPasswordVcObj?.removeConstraints()
        addLog(text: "Showing enter password view from quit")
    }

    override func viewWillDisappear() {
        if let pwView = enterPasswordVcObj?.view, view.subviews.contains(pwView) {
            pwView.removeFromSuperview()
        }
    }
}

// MARK: - Feature pause ("snooze") mechanism

// Temporarily suppresses individual Focus Bear features for a user-chosen window, then lets each
// feature switch itself back on automatically once the window passes — no app restart required.
//
// This backs the quit popup's "I don't want to turn everything off, just pause a few things for a
// bit" flow. Each feature stores a "snoozed until" Date in UserDefaults; the feature's existing
// runtime gate calls `FeatureSnooze.isSnoozed(_:)` and skips firing while that returns true. Once the
// date passes, `isSnoozed` starts returning false again (and clears the key), so the feature resumes
// on its own the next time its gate runs. This deliberately does NOT flip the persistent
// `SettingsManagerObject` flags (which sync to the server) — the pause is local and temporary.

/// A feature the quit popup can temporarily pause. `rawValue` builds its UserDefaults key and is used
/// as the analytics label — do not rename existing raw values.
enum SnoozableFeature: String, CaseIterable {
    case breakNotifications
    case meetingDetection
    case blockingPopups
    case habitNotifications

    /// UserDefaults key holding the `Date` until which this feature is paused.
    var snoozedUntilKey: String {
        "kUserdefaultsFeatureSnoozeUntil_" + rawValue
    }
}

enum FeatureSnooze {
    /// Pause `feature` until `date`.
    static func snooze(_ feature: SnoozableFeature, until date: Date) {
        UserDefaults.standard.set(date, forKey: feature.snoozedUntilKey)
    }

    /// Cancel a pause early (feature resumes immediately).
    static func clear(_ feature: SnoozableFeature) {
        UserDefaults.standard.removeObject(forKey: feature.snoozedUntilKey)
    }

    /// True while `feature` is inside its pause window. Expired pauses are cleared as a side effect so
    /// the key doesn't linger in UserDefaults.
    static func isSnoozed(_ feature: SnoozableFeature) -> Bool {
        guard let until = UserDefaults.standard.object(forKey: feature.snoozedUntilKey) as? Date else {
            return false
        }
        if Date() < until { return true }
        UserDefaults.standard.removeObject(forKey: feature.snoozedUntilKey)
        return false
    }
}

// MARK: - Constants (no magic strings/numbers)

/// Analytics events for the quit popup. `app-quit` is the historic event (kept so existing dashboards
/// keep working); the rest are new. Never rename the string *values* — only code references.
enum QuitPopupAnalytics {
    static let appQuit = "app-quit"
    static let reportBug = "quit-popup-report-bug"
    static let reasonBroken = "quit-popup-reason-broken"
    static let offUntilTomorrow = "quit-popup-off-until-tomorrow"
    static let snoozeFeatures = "quit-popup-snooze-features"
}

enum QuitPopupLayout {
    static let width: CGFloat = 620
    // Shared column width for the heading, checkboxes and pause control so their edges line up.
    static let columnWidth: CGFloat = 360
    // Sized to hug the primary (pause) screen's natural content height (measured via an offscreen
    // NSHostingView.fittingSize harness) plus a small safety margin, so there's no dead space at the
    // bottom. The (now off-screen) reason view's text editor flexes to fill this same height.
    static let height: CGFloat = 358
}

/// Pause-blocking duration bounds (hours) for the +/- stepper.
enum QuitPopupDuration {
    static let defaultPauseHours = 1
    static let minPauseHours = 1
    static let maxPauseHours = 8
    static let stepHours = 1
}

enum QuitPopupSchedule {
    /// The hour (local) the app should switch back on when the user picks "until tomorrow" — early enough
    /// that it's on again before the work day, late enough not to fire mid-sleep.
    static let untilTomorrowHour = 4

    static func tomorrowMorning() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
        var comps = cal.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = untilTomorrowHour
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps) ?? tomorrow
    }

    /// Tomorrow at the user's Focus Bear day start time (the global `startTime`), which is when "turn
    /// everything off until tomorrow" brings the app back on. Falls back to `untilTomorrowHour` when the
    /// start time isn't loaded/parseable yet — the same fallback the routine code uses for a missing
    /// startTime.
    static func tomorrowAtStartTime() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
        var comps = cal.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = startTime?.hour ?? untilTomorrowHour
        comps.minute = startTime?.minute ?? 0
        comps.second = 0
        return cal.date(from: comps) ?? tomorrow
    }
}

// MARK: - Strings (config-driven, English fallbacks)

/// User-facing copy for the quit popup. Reads new keys under `quitInfo.quitPopupInfo`, reusing existing
/// `quittingConfirmInfo` reason strings for the broken-app reason picker. Add the new keys to the
/// assets-repo config.json + config-es.json to localise them — the English fallbacks are used until then.
struct QuitPopupStrings {
    var title = "Quitting.."
    // Always-visible top action
    var reportBugButton = "🐞 Report a bug"
    // Primary screen — heading, the pause control, the whole-app link, and the uninstall hint
    var pauseTitle = "What features do you want to turn off?"
    var pauseForLabel = "Pause for"
    var offUntilTomorrowButton = "Turn everything off until tomorrow"
    var uninstallHint = "To uninstall, go to Settings > Uninstall"
    // Feature toggle labels
    var featureBreaks = "Break reminders"
    var featureMeetings = "Meeting-detected alerts"
    var featureBlocking = "Blocking & distraction pop-ups"
    var featureHabits = "Habit reminders"
    // Broken branch — reason capture
    var reasonSubtitle = "Sorry to hear that. What went wrong?"
    var reasonFeedbackPrompt = "Tell us what happened so we can fix it (optional):"
    var reasonQuitButton = "Turn Focus Bear off"
    var cancelButton = "Never mind"
    // Reason picker options (reused from the existing quit-confirm config)
    var reasonFocusMode = "My focus modes are not working properly"
    var reasonHabits = "My habits are not working properly"
    var reasonBlocking = "The blocking features are not working properly"
    var reasonAnnoying = "I'm finding Focus Bear annoying"
    var reasonSomethingElse = "Something else"

    static func load() -> QuitPopupStrings {
        var s = QuitPopupStrings()
        guard let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary else { return s }
        s.title = quitInfo.value(forKey: "quittingTitle") as? String ?? s.title
        if let info = quitInfo.value(forKey: "quitPopupInfo") as? NSDictionary {
            s.reportBugButton = info.value(forKey: "reportBugButton") as? String ?? s.reportBugButton
            s.pauseTitle = info.value(forKey: "pauseTitle") as? String ?? s.pauseTitle
            s.pauseForLabel = info.value(forKey: "pauseForLabel") as? String ?? s.pauseForLabel
            s.offUntilTomorrowButton = info.value(forKey: "offUntilTomorrowButton") as? String ?? s.offUntilTomorrowButton
            s.uninstallHint = info.value(forKey: "uninstallHint") as? String ?? s.uninstallHint
            s.featureBreaks = info.value(forKey: "featureBreaks") as? String ?? s.featureBreaks
            s.featureMeetings = info.value(forKey: "featureMeetings") as? String ?? s.featureMeetings
            s.featureBlocking = info.value(forKey: "featureBlocking") as? String ?? s.featureBlocking
            s.featureHabits = info.value(forKey: "featureHabits") as? String ?? s.featureHabits
            s.reasonSubtitle = info.value(forKey: "reasonSubtitle") as? String ?? s.reasonSubtitle
            s.reasonFeedbackPrompt = info.value(forKey: "reasonFeedbackPrompt") as? String ?? s.reasonFeedbackPrompt
            s.reasonQuitButton = info.value(forKey: "reasonQuitButton") as? String ?? s.reasonQuitButton
            s.cancelButton = info.value(forKey: "cancelButton") as? String ?? s.cancelButton
        }
        if let confirm = quitInfo.value(forKey: "quittingConfirmInfo") as? NSDictionary,
           let notWorking = confirm.value(forKey: "dropDownAppNotWorking") as? NSDictionary {
            s.reasonFocusMode = notWorking.value(forKey: "reasonFocusMode") as? String ?? s.reasonFocusMode
            s.reasonHabits = notWorking.value(forKey: "reasonHabits") as? String ?? s.reasonHabits
            s.reasonBlocking = notWorking.value(forKey: "reasonBlocking") as? String ?? s.reasonBlocking
            if let annoying = confirm.value(forKey: "dropDownAnnoying") as? NSDictionary,
               let t = annoying.value(forKey: "title") as? String { s.reasonAnnoying = t }
            if let somethingElse = confirm.value(forKey: "dropDown_3") as? NSDictionary,
               let t = somethingElse.value(forKey: "title") as? String { s.reasonSomethingElse = t }
        }
        return s
    }

    var reasonOptions: [String] {
        [reasonFocusMode, reasonHabits, reasonBlocking, reasonAnnoying, reasonSomethingElse]
    }

    func label(for feature: SnoozableFeature) -> String {
        switch feature {
        case .breakNotifications: return featureBreaks
        case .meetingDetection: return featureMeetings
        case .blockingPopups: return featureBlocking
        case .habitNotifications: return featureHabits
        }
    }
}

// MARK: - SwiftUI view

private enum QuitPopupPhase { case pause, reason }

/// Transient UI state that must NOT survive a close/reopen of the quit window. The quit view controller
/// is a reused singleton, so SwiftUI `@State` would keep the previous open's value — after one action the
/// reopened window came back with everything disabled and the loader stuck (#2584). Held in an
/// ObservableObject the view controller owns so `resetData()` can clear it on every open.
final class QuitPopupModel: ObservableObject {
    /// True while an action (pause / off-until-tomorrow / quit-broken) is running its ~1s beat.
    @Published var isBusy = false
}

struct QuitPopupView: View {
    let strings: QuitPopupStrings
    let onCancel: () -> Void
    let onReportBug: () -> Void
    let onQuitBroken: (String, String) -> Void   // (reason, feedback)
    let onOffUntilTomorrow: () -> Void
    let onSnoozeFeatures: (Set<SnoozableFeature>, Int) -> Void   // (features, hours)

    // The app defines global `State`/`Button` types that shadow SwiftUI's — qualify them.
    // The pause/toggles screen is the primary front door (the user asked to land directly on "choose
    // what to pause and for how long"); the reason-capture screen is reached from a small link.
    @SwiftUI.State private var phase: QuitPopupPhase = .pause
    @SwiftUI.State private var selectedReason: String
    @SwiftUI.State private var feedback: String = ""
    @SwiftUI.State private var pauseHours: Int = QuitPopupDuration.defaultPauseHours
    // Which reminders the user wants to pause. Defaults to blocking pop-ups selected (the most common
    // "give me a quick breather" case); the user ticks the rest as needed.
    @SwiftUI.State private var selectedFeatures: Set<SnoozableFeature> = [.blockingPopups]
    // isBusy lives on the VC-owned model (not @State) so it survives no close/reopen — see QuitPopupModel.
    @ObservedObject private var model: QuitPopupModel
    private var isBusy: Bool { model.isBusy }

    init(strings: QuitPopupStrings,
         model: QuitPopupModel,
         onCancel: @escaping () -> Void,
         onReportBug: @escaping () -> Void,
         onQuitBroken: @escaping (String, String) -> Void,
         onOffUntilTomorrow: @escaping () -> Void,
         onSnoozeFeatures: @escaping (Set<SnoozableFeature>, Int) -> Void) {
        self.strings = strings
        _model = ObservedObject(wrappedValue: model)
        self.onCancel = onCancel
        self.onReportBug = onReportBug
        self.onQuitBroken = onQuitBroken
        self.onOffUntilTomorrow = onOffUntilTomorrow
        self.onSnoozeFeatures = onSnoozeFeatures
        _selectedReason = SwiftUI.State(initialValue: strings.reasonOptions.first ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Group {
                switch phase {
                case .pause: pauseView
                case .reason: reasonView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: QuitPopupLayout.width, height: QuitPopupLayout.height)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UITestContract.Identifier.SettingsRegression.quitPopup)
    }

    // "Report a bug" sits at the very top so a frustrated user can always reach the existing Report
    // Problem flow without first arguing with the quit dialog. Centred title stays visually centred by
    // balancing the trailing button with an equal-width leading spacer.
    private var header: some View {
        ZStack {
            Text(strings.title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                SwiftUI.Button(strings.reportBugButton) { onReportBug() }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // Primary (and only on-screen) screen — choose which reminders to pause and for how long. The orange
    // control IS the pause button: tapping its centre pauses the selected features for the shown duration;
    // the − / + only adjust the duration. A whole-app "turn everything off until tomorrow" text link and a
    // small uninstall hint sit below. Everything is constrained to a shared column so edges line up.
    private var pauseView: some View {
        VStack(spacing: 16) {
            Text(strings.pauseTitle)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: QuitPopupLayout.columnWidth)
            featureToggles
            pauseControl
            SwiftUI.Button { run(onOffUntilTomorrow) } label: {
                // Spinner sits inline in the label rather than on its own row: this VStack lives in a
                // fixed-height (358pt) frame, so an extra row when isBusy flipped true pushed the uninstall
                // hint below the frame and clipped it out of bounds.
                HStack(spacing: 8) {
                    Text(strings.offUntilTomorrowButton)
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .underline()
                    if isBusy { ProgressView().scaleEffect(0.5) }
                }
            }
                .buttonStyle(PlainButtonStyle())
                .disabled(isBusy)
                .pointingHandCursor()
            Text(strings.uninstallHint)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // Secondary screen (reached from the "something's broken?" link): reason picker + optional feedback +
    // quit. The text editor stretches to fill the remaining height so there's no dead space at the bottom.
    private var reasonView: some View {
        VStack(spacing: 12) {
            Text(strings.reasonSubtitle)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Picker("", selection: $selectedReason) {
                ForEach(strings.reasonOptions, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .frame(maxWidth: 420)
            Text(strings.reasonFeedbackPrompt)
                .font(.callout).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $feedback)
                .font(.body)
                .frame(minHeight: 80, maxHeight: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.35), lineWidth: 1))
            HStack(spacing: 12) {
                SwiftUI.Button(strings.cancelButton, action: onCancel)
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 40))
                SwiftUI.Button(strings.reasonQuitButton) {
                    run { onQuitBroken(selectedReason, feedback) }
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 40))
                .disabled(isBusy)
                if isBusy { ProgressView().scaleEffect(0.6) }
            }
        }
        .padding(20)
    }

    private var featureToggles: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(SnoozableFeature.allCases, id: \.self) { feature in
                SwiftUI.Toggle(isOn: binding(for: feature)) {
                    Text(strings.label(for: feature)).font(.system(size: 14))
                }
                .toggleStyle(.checkbox)
            }
        }
        .frame(maxWidth: QuitPopupLayout.columnWidth, alignment: .leading)
    }

    private func binding(for feature: SnoozableFeature) -> SwiftUI.Binding<Bool> {
        SwiftUI.Binding(
            get: { selectedFeatures.contains(feature) },
            set: { isOn in
                if isOn { selectedFeatures.insert(feature) } else { selectedFeatures.remove(feature) }
            })
    }

    // The orange bar doubles as the pause button: [ − ]  "Pause for" / "N hours"  [ + ]. The centre is a
    // button that pauses the selected features for `pauseHours`; the − / + adjust the duration without
    // pausing. Dimmed while no feature is selected (centre tap disabled), but − / + stay live.
    private var pauseControl: some View {
        HStack(spacing: 0) {
            QuitStepperButton(systemName: "minus") { adjustPauseHours(-QuitPopupDuration.stepHours) }
            SwiftUI.Button(action: { run { onSnoozeFeatures(selectedFeatures, pauseHours) } }) {
                VStack(spacing: 1) {
                    Text(strings.pauseForLabel)
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(pauseHours) \(pauseHours == 1 ? hourText : hoursText)")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isBusy || selectedFeatures.isEmpty)
            QuitStepperButton(systemName: "plus") { adjustPauseHours(QuitPopupDuration.stepHours) }
        }
        .foregroundColor(.white)
        .padding(.vertical, 10)
        .frame(maxWidth: QuitPopupLayout.columnWidth)
        .background(MenuTheme.orange)
        .opacity(selectedFeatures.isEmpty ? 0.55 : 1)
        .cornerRadius(12)
        .shadow(color: MenuTheme.orange.opacity(0.30), radius: 5, x: 0, y: 2)
    }

    private func adjustPauseHours(_ delta: Int) {
        pauseHours = min(QuitPopupDuration.maxPauseHours, max(QuitPopupDuration.minPauseHours, pauseHours + delta))
    }

    private func run(_ action: () -> Void) {
        guard !model.isBusy else { return }
        model.isBusy = true
        action()
    }
}

/// Minus / plus button for the pause-blocking duration bar — mirrors the menu's stepper icon styling
/// (white glyph, fixed hit area) without depending on that file's `private` control.
private struct QuitStepperButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 42, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}
