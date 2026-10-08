//
//  BlockingSchedulePresetsView.swift
//  Focus Bear
//
//  "Quick-Start Presets" grid shown when adding a new blocking schedule
//  (Figma preset screen). Picking a preset opens the editor pre-filled; the
//  "Custom Schedule" tile opens a blank editor.
//

import SwiftUI

private typealias SettingsUITestIdentifier = UITestContract.Identifier.SettingsRegression

/// A starter template for a blocking schedule. Client-side only — picking one
/// just pre-fills the editor, so there's no persistence/backend involvement.
struct SchedulePreset: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let days: [Int]            // 1 = Sun ... 7 = Sat
    let startMinutes: Int
    let endMinutes: Int
    let strictness: FOCUSMODESTRICTNESS
    let isCustom: Bool

    static let all: [SchedulePreset] = [
        SchedulePreset(name: "Work Focus", emoji: "💻", days: [2, 3, 4, 5, 6],
                       startMinutes: 9 * 60, endMinutes: 17 * 60, strictness: ._STRICT_, isCustom: false),
        SchedulePreset(name: "Mindful Morning", emoji: "🌅", days: [1, 2, 3, 4, 5, 6, 7],
                       startMinutes: 6 * 60, endMinutes: 9 * 60, strictness: ._NORMAL_, isCustom: false),
        SchedulePreset(name: "Evening Unwind", emoji: "🌙", days: [1, 2, 3, 4, 5, 6, 7],
                       startMinutes: 20 * 60, endMinutes: 23 * 60, strictness: ._NORMAL_, isCustom: false),
        SchedulePreset(name: "Quick Focus Burst", emoji: "⚡️", days: [2, 3, 4, 5, 6],
                       startMinutes: 13 * 60, endMinutes: 14 * 60, strictness: ._SUPER_STRICT_, isCustom: false),
        SchedulePreset(name: "Weekend Detach", emoji: "🏕️", days: [1, 7],
                       startMinutes: 8 * 60, endMinutes: 22 * 60, strictness: ._STRICT_, isCustom: false),
        SchedulePreset(name: "Custom Schedule", emoji: "🛠️", days: [],
                       startMinutes: 9 * 60, endMinutes: 17 * 60, strictness: ._NORMAL_, isCustom: true),
    ]
}

@available(macOS 11.0, *)
struct BlockingSchedulePresetsView: View {
    var onPick: (SchedulePreset) -> Void
    var onBack: () -> Void
    /// Hidden in onboarding, where the screen already has the onboarding title bar, progress and back
    /// button — the built-in header would duplicate them. Defaults to true so the running app is unchanged.
    var showHeader: Bool = true

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                BlockingScheduleHeader(title: "Quick-Start Presets", onBack: onBack)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SchedulePreset.all) { preset in
                        SwiftUI.Button(action: { onPick(preset) }) {
                            presetCard(preset)
                        }
                        .buttonStyle(FBButtonStyle())
                        .accessibilityIdentifier(SettingsUITestIdentifier.schedulePresetPrefix
                                                 + String(SchedulePreset.all.firstIndex { $0.id == preset.id } ?? 0))
                    }
                }
                .padding(20)
            }
        }
        .background(FBColor.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SettingsUITestIdentifier.schedulePresets)
    }

    private func presetCard(_ preset: SchedulePreset) -> some View {
        VStack(spacing: 8) {
            Text(preset.emoji).font(.system(size: 34))
            Text(preset.name)
                .font(.fbSemibold(14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            if !preset.isCustom {
                Text(subtitle(preset))
                    .font(.fbRegular(11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(RoundedRectangle(cornerRadius: 12).fill(FBColor.lightOrangeBackground.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FBColor.lightOrangeBorder, lineWidth: 1))
    }

    private func subtitle(_ preset: SchedulePreset) -> String {
        "\(preset.days.formattedDays())\n\(BlockingScheduleStore.hhmm(fromMinutes: preset.startMinutes)) – \(BlockingScheduleStore.hhmm(fromMinutes: preset.endMinutes))"
    }
}
