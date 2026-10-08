//
//  BlockingScheduleHomeView.swift
//  Focus Bear
//
//  Top-level SwiftUI view for the redesigned blocking-schedules screen:
//  a header + a List/Calendar tab switcher, a permissions banner, and the
//  Quick-Start Presets flow when adding a schedule. (Geek⟷Simple lives in the
//  parent AppKit container's segmented control, so it isn't duplicated here.)
//

import SwiftUI

@available(macOS 11.0, *)
struct BlockingScheduleHomeView: View {
    @ObservedObject var store: BlockingScheduleStore

    var onBack: () -> Void
    var onSelectIndex: (Int) -> Void
    var onSelectScheduleID: (String) -> Void
    var onAdd: () -> Void                 // blank editor (Custom)
    var onPickPreset: (SchedulePreset) -> Void
    var onCreate: (_ weekday: Int, _ startMinutes: Int, _ endMinutes: Int) -> Void
    var onEnablePermissions: () -> Void

    enum Tab { case list, calendar }
    @SwiftUI.State private var tab: Tab = .list
    @SwiftUI.State private var showingPresets = false

    var body: some View {
        VStack(spacing: 0) {
            if showingPresets {
                BlockingSchedulePresetsView(
                    onPick: { preset in
                        showingPresets = false
                        if preset.isCustom { onAdd() } else { onPickPreset(preset) }
                    },
                    onBack: { showingPresets = false })
            } else {
                header
                if store.permissionsNeeded { permissionsBanner }
                tabBar
                Divider()
                content
            }
        }
        .background(FBColor.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UITestContract.Identifier.Blocking.blockingSchedulesEditor)
    }

    private var header: some View {
        BlockingScheduleHeader(title: "Blocking Schedule", onBack: onBack)
    }

    private var permissionsBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(FBColor.accent)
            Text("Grant Focus Bear permissions so blocking can work.")
                .font(.fbMedium(12))
                .foregroundColor(.primary)
            Spacer(minLength: 8)
            SwiftUI.Button(action: onEnablePermissions) {
                Text("Enable")
                    .font(.fbSemibold(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Capsule().fill(FBColor.accent))
            }
            .buttonStyle(FBButtonStyle())
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(FBColor.lightOrangeBackground.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FBColor.lightOrangeBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var tabBar: some View {
        HStack(spacing: 24) {
            tabButton("List", .list)
            tabButton("Calendar", .calendar)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .padding(.top, 6)
    }

    private func tabButton(_ title: String, _ value: Tab) -> some View {
        let selected = tab == value
        return SwiftUI.Button(action: { tab = value }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.fbSemibold(14))
                    .foregroundColor(selected ? FBColor.accent : .secondary)
                Rectangle()
                    .fill(selected ? FBColor.accent : Color.clear)
                    .frame(height: 2)
            }
            .fixedSize()
        }
        .buttonStyle(FBButtonStyle())
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .list:
            BlockingScheduleListView(store: store,
                                     onSelect: onSelectIndex,
                                     onAdd: { showingPresets = true })
        case .calendar:
            BlockingScheduleCalendarView(store: store,
                                         onSelectSchedule: onSelectScheduleID,
                                         onCreate: onCreate,
                                         onAdd: { showingPresets = true })
        }
    }
}
