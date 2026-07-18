//
//  TalkingClockSettingsView.swift
//  Focus Bear
//
//  SwiftUI rewrite of the Talking Clock settings screen (#1771). New/modified UI must be SwiftUI (the
//  storyboard can no longer be edited), so talkingClockSettingsVc now just hosts this view. All the
//  underlying logic still lives in TalkingClockManager / SettingsManager.
//

import SwiftUI

/// Bridges the SwiftUI controls to SettingsManager + TalkingClockManager (which are plain AppKit types).
final class TalkingClockSettingsModel: ObservableObject {
    let intervalOptions = [15, 30, 60]

    @Published var enabled: Bool {
        didSet {
            guard oldValue != enabled else { return }
            SettingsManagerObject.isTalkingClockEnabled = enabled
            persist()
            if enabled {
                TalkingClockManager.shared.start()
                allApiObject.capturePosthog(event: "settings-changed-enable-talking-clock", metadata: [:])
            } else {
                TalkingClockManager.shared.stop()
                allApiObject.capturePosthog(event: "settings-changed-disable-talking-clock", metadata: [:])
            }
        }
    }

    @Published var intervalMinutes: Int {
        didSet {
            guard oldValue != intervalMinutes else { return }
            SettingsManagerObject.talkingClockIntervalMinutes = intervalMinutes
            persist()
            TalkingClockManager.shared.restart()
        }
    }

    @Published var suppressDuringMeetings: Bool {
        didSet {
            guard oldValue != suppressDuringMeetings else { return }
            SettingsManagerObject.talkingClockSuppressDuringMeetings = suppressDuringMeetings
            persist()
        }
    }

    @Published var quietStartHour: Int { didSet { guard oldValue != quietStartHour else { return }; clampAndSaveQuietHours() } }
    @Published var quietStartMinute: Int { didSet { guard oldValue != quietStartMinute else { return }; clampAndSaveQuietHours() } }
    @Published var quietEndHour: Int { didSet { guard oldValue != quietEndHour else { return }; clampAndSaveQuietHours() } }
    @Published var quietEndMinute: Int { didSet { guard oldValue != quietEndMinute else { return }; clampAndSaveQuietHours() } }

    private var isLoading = true

    // Titles used to register the two toggles in settings search.
    var enableSearchTitle: String { TalkingClockSettingsStrings.load().enableTitle }
    var suppressSearchTitle: String { TalkingClockSettingsStrings.load().suppressTitle }

    init() {
        enabled = SettingsManagerObject.isTalkingClockEnabled
        intervalMinutes = intervalOptions.contains(SettingsManagerObject.talkingClockIntervalMinutes)
            ? SettingsManagerObject.talkingClockIntervalMinutes : 30
        suppressDuringMeetings = SettingsManagerObject.talkingClockSuppressDuringMeetings
        quietStartHour = SettingsManagerObject.talkingClockQuietStartHour
        quietStartMinute = SettingsManagerObject.talkingClockQuietStartMinute
        quietEndHour = SettingsManagerObject.talkingClockQuietEndHour
        quietEndMinute = SettingsManagerObject.talkingClockQuietEndMinute
        isLoading = false
    }

    private func persist() {
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
    }

    private func clampAndSaveQuietHours() {
        guard !isLoading else { return }
        quietStartHour = min(max(quietStartHour, 0), 23)
        quietStartMinute = min(max(quietStartMinute, 0), 59)
        quietEndHour = min(max(quietEndHour, 0), 23)
        quietEndMinute = min(max(quietEndMinute, 0), 59)
        SettingsManagerObject.talkingClockQuietStartHour = quietStartHour
        SettingsManagerObject.talkingClockQuietStartMinute = quietStartMinute
        SettingsManagerObject.talkingClockQuietEndHour = quietEndHour
        SettingsManagerObject.talkingClockQuietEndMinute = quietEndMinute
        persist()
    }
}

struct TalkingClockSettingsView: View {
    @ObservedObject var model: TalkingClockSettingsModel
    let onBack: () -> Void

    // Localized copy (config `talkingClockSettingsInfo`, English fallbacks).
    private let strings = TalkingClockSettingsStrings.load()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SwiftUI.Button(action: onBack) {
                HStack(spacing: 4) { Image(systemName: "chevron.left"); Text(strings.back) }
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Text(strings.title).font(.title2).fontWeight(.semibold)

            Toggle(isOn: $model.enabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings.enableTitle)
                    Text(strings.enableSubtitle).font(.caption).foregroundColor(.secondary)
                }
            }

            HStack {
                Text(strings.announceEvery)
                Picker("", selection: $model.intervalMinutes) {
                    ForEach(model.intervalOptions, id: \.self) { m in
                        Text("\(m) \(strings.minutes)").tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(strings.quietHours).foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Text(strings.start)
                    timeField($model.quietStartHour, range: 0...23)
                    Text(":")
                    timeField($model.quietStartMinute, range: 0...59)
                }
                HStack(spacing: 6) {
                    Text(strings.end)
                    timeField($model.quietEndHour, range: 0...23)
                    Text(":")
                    timeField($model.quietEndMinute, range: 0...59)
                }
            }

            Toggle(isOn: $model.suppressDuringMeetings) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings.suppressTitle)
                    Text(strings.suppressSubtitle).font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 420, alignment: .leading)
    }

    private func timeField(_ value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            Text(String(format: "%02d", value.wrappedValue))
                .font(.body.monospacedDigit())
                .frame(minWidth: 28)
        }
        .fixedSize()
    }
}

/// Localized strings for the Talking Clock settings screen (config override + English fallback).
struct TalkingClockSettingsStrings {
    var title = "Talking Clock"
    var back = "Back"
    var enableTitle = "Enable talking clock"
    var enableSubtitle = "Announce the current time at regular intervals to help you stay time-aware."
    var announceEvery = "Announce every"
    var minutes = "minutes"
    var quietHours = "Quiet hours (no announcements between these times)"
    var start = "Start:"
    var end = "End:"
    var suppressTitle = "Suppress during meetings"
    var suppressSubtitle = "Don't announce the time when you're in a meeting focus mode."

    static func load() -> TalkingClockSettingsStrings {
        var s = TalkingClockSettingsStrings()
        guard let info = configjson.value(forKey: "talkingClockSettingsInfo") as? NSDictionary else { return s }
        func str(_ key: String, _ current: String) -> String { info.value(forKey: key) as? String ?? current }
        s.title = str("title", s.title)
        s.back = str("back", s.back)
        s.enableTitle = str("enableTitle", s.enableTitle)
        s.enableSubtitle = str("enableSubtitle", s.enableSubtitle)
        s.announceEvery = str("announceEvery", s.announceEvery)
        s.minutes = str("minutes", s.minutes)
        s.quietHours = str("quietHours", s.quietHours)
        s.start = str("start", s.start)
        s.end = str("end", s.end)
        s.suppressTitle = str("suppressTitle", s.suppressTitle)
        s.suppressSubtitle = str("suppressSubtitle", s.suppressSubtitle)
        return s
    }
}
