//
//  BlockingScheduleListView.swift
//  Focus Bear
//
//  "List" tab of the redesigned blocking-schedules screen (Figma Phase 1.1):
//  one card per schedule + an "add new" button. Tapping a card opens the
//  existing AppKit editor.
//

import SwiftUI

private typealias SettingsUITestIdentifier = UITestContract.Identifier.SettingsRegression

@available(macOS 11.0, *)
struct BlockingScheduleListView: View {
    @ObservedObject var store: BlockingScheduleStore
    /// Called with the index of the tapped schedule (into store.schedules).
    var onSelect: (Int) -> Void
    var onAdd: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Array(store.schedules.enumerated()), id: \.element.id) { index, schedule in
                    SwiftUI.Button(action: { onSelect(index) }) {
                        ScheduleCard(store: store, schedule: schedule, colorIndex: index)
                    }
                    .buttonStyle(FBButtonStyle())
                    .accessibilityIdentifier(SettingsUITestIdentifier.scheduleCardPrefix + schedule.name)
                }

                addButton
            }
            .padding(20)
        }
    }

    private var addButton: some View {
        SwiftUI.Button(action: onAdd) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add new block schedule")
            }
            .font(.fbSemibold(14))
            .foregroundColor(FBColor.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundColor(FBColor.accent.opacity(0.7))
            )
        }
        .buttonStyle(FBButtonStyle())
        .accessibilityIdentifier(SettingsUITestIdentifier.scheduleAddButton)
        .padding(.top, 4)
    }
}

@available(macOS 11.0, *)
private struct ScheduleCard: View {
    @ObservedObject var store: BlockingScheduleStore
    let schedule: customBlockingSchedule
    let colorIndex: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(FBColor.scheduleColor(colorIndex))
                .frame(width: 5)
            Text(emoji(for: schedule))
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 10) {
                Text(schedule.name)
                    .font(.fbSemibold(15))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(schedule.startTime.formattedTime()) to \(schedule.endTime.formattedTime())")
                    .font(.fbMedium(13))
                    .foregroundColor(FBColor.accent)

                // wrap pills so a narrow settings pane doesn't clip them
                FlowPills(pills: pills)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FBColor.lightOrangeBackground.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(FBColor.lightOrangeBorder, lineWidth: 1)
        )
    }

    private var pills: [PillSpec] {
        [
            PillSpec(text: schedule.daysOfWeek.formattedDays(),
                     fill: FBColor.fieldBackground, textColor: .primary, border: FBColor.grayBorder),
            // fill + .primary text are both appearance-adaptive (cream/near-black bg, black/white text),
            // so this stays readable in Light and Dark.
            PillSpec(text: store.blockListName(for: schedule),
                     fill: FBColor.lightOrangeBackground, textColor: .primary, border: FBColor.lightOrangeBorder),
            PillSpec(text: schedule.blockLevelString,
                     fill: schedule.blockLevel.blockFill, textColor: schedule.blockLevel.onBlockColor, border: .clear),
        ]
    }

    /// Prefer the user-chosen emoji (backend#2093); fall back to a deterministic
    /// one so cards still look lively before an emoji is set.
    private func emoji(for schedule: customBlockingSchedule) -> String {
        if let chosen = schedule.emoji, !chosen.isEmpty { return chosen }
        let set = ["🧠", "🌅", "🌙", "⚡️", "🏕️", "🛠️", "🎯", "😎", "💪", "📵"]
        let hash = abs(schedule.id.hashValue)
        return set[hash % set.count]
    }
}

// MARK: - Pills

struct PillSpec: Identifiable {
    let id = UUID()
    let text: String
    let fill: Color
    let textColor: Color
    let border: Color
}

@available(macOS 11.0, *)
private struct PillView: View {
    let spec: PillSpec
    var body: some View {
        Text(spec.text)
            .font(.fbMedium(12))
            .foregroundColor(spec.textColor)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(spec.fill))
            .overlay(Capsule().strokeBorder(spec.border, lineWidth: 1))
    }
}

/// Simple left-aligned wrapping row of pills (macOS 11-compatible; avoids the
/// macOS 13 `Layout`/`Grid` APIs).
@available(macOS 11.0, *)
private struct FlowPills: View {
    let pills: [PillSpec]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // two-per-row wrap keeps it readable in the narrow settings pane
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 6) {
                    ForEach(rows[i]) { PillView(spec: $0) }
                }
            }
        }
    }

    private var rows: [[PillSpec]] {
        var result: [[PillSpec]] = []
        var current: [PillSpec] = []
        for pill in pills {
            current.append(pill)
            if current.count == 2 { result.append(current); current = [] }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
