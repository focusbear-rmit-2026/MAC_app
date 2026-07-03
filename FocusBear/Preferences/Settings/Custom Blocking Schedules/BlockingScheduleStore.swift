//
//  BlockingScheduleStore.swift
//  Focus Bear
//
//  SwiftUI redesign of the blocking-schedules screen (List + Calendar).
//  This file holds the observable store that bridges the existing
//  `customBlockingScheduleManagerObj` (AppKit/global state) to SwiftUI, plus
//  the shared styling helpers + the calendar layout model.
//

import SwiftUI
import AppKit

// MARK: - Styling helpers

/// App font bridge → SwiftUI. Mirrors getRegularFont/getBoldFont(size:) so the
/// redesigned screens pick up the user's selected font like the rest of the app.
extension Font {
    static func fbRegular(_ size: CGFloat) -> Font { Font(getRegularFont(size: size)) }
    static func fbMedium(_ size: CGFloat) -> Font { Font(getMediumFont(size: size)) }
    static func fbSemibold(_ size: CGFloat) -> Font { Font(getSemiBoldFont(size: size)) }
    static func fbBold(_ size: CGFloat) -> Font { Font(getBoldFont(size: size)) }
}

// MARK: - Buttons (shared rules)

/// Shows the macOS pointing-hand cursor while the pointer is over the view, so
/// the whole area reads as clickable. Push/pop keeps the cursor stable during
/// hover; the disappear guard avoids leaving a pushed cursor on the stack if the
/// view goes away mid-hover.
@available(macOS 11.0, *)
private struct PointingHandCursorModifier: ViewModifier {
    @SwiftUI.State private var hovering = false
    func body(content: Content) -> some View {
        content
            .onHover { inside in
                guard inside != hovering else { return }
                hovering = inside
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            .onDisappear {
                if hovering { NSCursor.pop(); hovering = false }
            }
    }
}

@available(macOS 11.0, *)
extension View {
    /// Pointing-hand cursor on hover — every clickable control should use it.
    func pointingHandCursor() -> some View { modifier(PointingHandCursorModifier()) }
}

/// Shared button style for the blocking-schedule redesign. Enforces the two
/// app-wide button rules in ONE place so every button gets them for free:
///   1. the ENTIRE visible area is clickable (`contentShape(Rectangle())`), not
///      just the text/icon — matters for stroke-only or `Spacer`-padded labels;
///   2. the pointing-hand cursor shows on hover across that whole area.
/// Visually identical to `PlainButtonStyle` (no bezel, no press chrome).
@available(macOS 11.0, *)
struct FBButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            // Match the old AppKit `Button` class's press feedback: on mouse-down its fill
            // dims to ~0.7 (buttonDownColor = accent @ 0.7 alpha). Approximate that for every
            // button by dimming the whole label while pressed.
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .pointingHandCursor()
    }
}

@available(macOS 11.0, *)
extension View {
    /// Outlined "secondary" button label — rounded border + padding. This is the
    /// Cancel button's look; reuse it so Delete (and any other secondary action)
    /// matches. Pair with `.buttonStyle(FBButtonStyle())`.
    func fbOutlineButtonLabel(_ color: Color = .primary) -> some View {
        self.font(.fbSemibold(13))
            .foregroundColor(color)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(FBColor.grayBorder, lineWidth: 1))
    }
}

/// Back button matching the Browser Tab Limiter pane: a native bordered (regularSquare bevel) push
/// button showing the system left-facing triangle, instead of a flat SwiftUI chevron. Uses the app's
/// `cursorButton` NSButton subclass so it also gets the pointing-hand cursor.
@available(macOS 11.0, *)
struct BackPushButton: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> NSButton {
        let b = cursorButton()
        b.bezelStyle = .regularSquare
        b.setButtonType(.momentaryPushIn)
        b.isBordered = true
        b.imagePosition = .imageOnly
        b.imageScaling = .scaleProportionallyDown
        b.image = NSImage(named: NSImage.Name("NSLeftFacingTriangleTemplate"))
        b.target = context.coordinator
        b.action = #selector(Coordinator.fire)
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: 26),
            b.heightAnchor.constraint(equalToConstant: 26),
        ])
        return b
    }

    func updateNSView(_ nsView: NSButton, context: Context) { context.coordinator.action = action }

    func makeCoordinator() -> Coordinator { Coordinator(action) }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(_ action: @escaping () -> Void) { self.action = action }
        @objc func fire() { action() }
    }
}

/// Standard pane header, matching the app's other settings panes (e.g. officeModeSettingsVc / the
/// storyboard panes): a 50pt-high bar with the title vertically centred at `fbSemibold(14)` and a
/// 20pt leading inset, an optional back button to the left of the title, and a full-width separator
/// directly below. Use this so every redesigned screen's header looks and spaces the same.
@available(macOS 11.0, *)
struct BlockingScheduleHeader: View {
    let title: String
    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if let onBack = onBack {
                    BackPushButton(action: onBack)
                }
                Text(title)
                    .font(.fbSemibold(14))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(height: 50)          // 50pt band, title vertically centred
            Divider()                   // full-width separator below the header
        }
    }
}

/// Named colours from the asset catalogue (keeps the redesign on-theme without
/// hard-coding hex values that could drift from the rest of the app).
enum FBColor {
    static let background = Color("backgroundColor")
    static let accent = Color("dark_OrangeColor")
    /// Surface tint for cards / pills / banners. Light Mode keeps the soft cream; in Dark Mode that
    /// cream washed out at low opacity over the dark pane (muddy, low-contrast), so use a near-black
    /// panel that reads as a subtly recessed surface (defined by `lightOrangeBorder`) at the same
    /// 0.3–0.5 opacities.
    static let lightOrangeBackground = Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark
            ? NSColor(srgbRed: 0.09, green: 0.09, blue: 0.10, alpha: 1)      // near-black recessed panel (Dark)
            : NSColor(srgbRed: 1.0, green: 0.996, blue: 0.969, alpha: 1)     // existing cream (Light)
    })
    /// Matching warm border for the surfaces above — a muted warm tone in Dark instead of the bright
    /// peach (which looked out of place on the dark cards).
    static let lightOrangeBorder = Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark
            ? NSColor(srgbRed: 0.42, green: 0.33, blue: 0.24, alpha: 1)
            : NSColor(srgbRed: 0.973, green: 0.855, blue: 0.718, alpha: 1)
    })
    static let grayBorder = Color("grayBorderColor")

    /// Adaptive control/field background — white in Light, dark grey in Dark (bridges
    /// `NSColor.textBackgroundColor`). The `lightOrange*` asset colours have no Dark variant, so a
    /// fixed white fill would keep white-on-white text in Dark Mode; use this for fields, the
    /// block-list dropdown and pills that need an opaque background.
    static let fieldBackground = Color(NSColor.textBackgroundColor)

    /// Distinct colour per schedule so blocks are easy to tell apart on the
    /// calendar (and matched on the list). Orange leads to stay on-brand.
    static let schedulePalette: [Color] = [
        Color(red: 0.95, green: 0.55, blue: 0.15), // orange
        Color(red: 0.20, green: 0.64, blue: 0.62), // teal
        Color(red: 0.27, green: 0.52, blue: 0.82), // blue
        Color(red: 0.56, green: 0.40, blue: 0.78), // purple
        Color(red: 0.36, green: 0.68, blue: 0.40), // green
        Color(red: 0.87, green: 0.40, blue: 0.47), // pink
        Color(red: 0.84, green: 0.64, blue: 0.20), // amber
        Color(red: 0.40, green: 0.47, blue: 0.76), // indigo
    ]

    static func scheduleColor(_ index: Int) -> Color {
        let n = schedulePalette.count
        return schedulePalette[((index % n) + n) % n]
    }
}

extension FOCUSMODESTRICTNESS {
    /// Fill colour used for the strictness pill + calendar block, getting more
    /// saturated as the schedule gets stricter (matches the Figma redesign).
    var blockFill: Color {
        Color("dark_OrangeColor")
    }

    /// Text colour that stays readable on top of `blockFill`.
    var onBlockColor: Color {
        Color.white
    }
}

// MARK: - Calendar layout model

/// A single drawable segment on the timeline. A weekly schedule produces one
/// segment per day it applies to; a schedule that crosses midnight produces a
/// segment on its start-day (until 24:00) and a continuation on the next day.
struct ScheduleSegment: Identifiable {
    let id: String
    let scheduleID: String
    let name: String
    let weekday: Int        // 1 = Sunday ... 7 = Saturday
    let startMinutes: Int   // minutes from midnight (0...1440)
    let endMinutes: Int     // minutes from midnight (> startMinutes, ≤ 1440)
    let blockLevel: FOCUSMODESTRICTNESS
    let isActive: Bool      // currently running
    let isContinuation: Bool // the wrapped-past-midnight tail of a schedule
    let colorIndex: Int     // palette index for a distinct per-schedule colour
}

// MARK: - Store

/// Observable bridge over the global blocking-schedule manager. SwiftUI reads
/// `schedules`; all mutations go back through the manager so the existing
/// timing/persistence/API logic keeps working unchanged.
@available(macOS 11.0, *)
final class BlockingScheduleStore: ObservableObject {

    @Published private(set) var schedules: [customBlockingSchedule] = []
    /// True when blocking permissions are missing — drives the SwiftUI banner.
    @Published var permissionsNeeded = false

    init() { reload() }

    /// Re-pull from the manager. Call when returning to the screen or after the
    /// AppKit editor adds/edits/deletes a schedule.
    func reload() {
        schedules = customBlockingScheduleManagerObj.arrBlockingSchedule
    }

    // MARK: Display helpers

    /// Human name of the block list (focus mode) backing a schedule.
    func blockListName(for schedule: customBlockingSchedule) -> String {
        for focusMode in arrFocusType where focusMode["id"] as? String == schedule.focusModeID {
            return focusMode["name"] as? String ?? ""
        }
        return "Update block list ⚠️"
    }

    /// Default block list id for newly drag-created schedules (first non-meeting
    /// focus mode), or "" when none — the editor then forces a selection.
    var defaultFocusModeID: String {
        for focusMode in arrFocusType where !(focusMode["isMeetings"] as? Bool ?? false) {
            return focusMode["id"] as? String ?? ""
        }
        return ""
    }

    // MARK: Calendar segments

    /// Build the segments to draw for the given weekdays (1...7).
    func segments(forWeekdays weekdays: [Int]) -> [ScheduleSegment] {
        var result: [ScheduleSegment] = []
        for (colorIndex, schedule) in schedules.enumerated() {
            let start = Self.minutes(from: schedule.startTimeString)
            let rawEnd = Self.minutes(from: schedule.endTimeString)
            let crossesMidnight = rawEnd <= start

            for day in schedule.daysOfWeek {
                // main segment on the start-day
                if weekdays.contains(day) {
                    let end = crossesMidnight ? 1440 : rawEnd
                    if end > start {
                        result.append(ScheduleSegment(
                            id: "\(schedule.id)-\(day)",
                            scheduleID: schedule.id,
                            name: schedule.name,
                            weekday: day,
                            startMinutes: start,
                            endMinutes: end,
                            blockLevel: schedule.blockLevel,
                            isActive: schedule.state == .on,
                            isContinuation: false,
                            colorIndex: colorIndex))
                    }
                }
                // wrapped tail on the following day
                if crossesMidnight && rawEnd > 0 {
                    let nextDay = day == 7 ? 1 : day + 1
                    if weekdays.contains(nextDay) {
                        result.append(ScheduleSegment(
                            id: "\(schedule.id)-\(nextDay)-cont",
                            scheduleID: schedule.id,
                            name: schedule.name,
                            weekday: nextDay,
                            startMinutes: 0,
                            endMinutes: rawEnd,
                            blockLevel: schedule.blockLevel,
                            isActive: schedule.state == .on,
                            isContinuation: true,
                            colorIndex: colorIndex))
                    }
                }
            }
        }
        return result
    }

    // MARK: Mutations (drag to resize / move)

    /// Persist new start/end times (minutes from midnight) for a schedule after
    /// a drag. Mirrors the editor's save path so timing + server stay in sync.
    func updateTimes(scheduleID: String, startMinutes: Int, endMinutes: Int) {
        guard let index = customBlockingScheduleManagerObj.arrBlockingSchedule
            .firstIndex(where: { $0.id == scheduleID }) else { return }

        let startStr = Self.hhmm(fromMinutes: startMinutes)
        let endStr = Self.hhmm(fromMinutes: endMinutes)

        let start = customBlockingSchedule.parseTime(startStr) ?? Date()
        var end = customBlockingSchedule.parseTime(endStr) ?? Date()
        if start > end { // cross-midnight: keep manager's convention of end+1day
            end = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
        }
        customBlockingScheduleManagerObj.arrBlockingSchedule[index].startTimeString = startStr
        customBlockingScheduleManagerObj.arrBlockingSchedule[index].endTimeString = endStr
        customBlockingScheduleManagerObj.arrBlockingSchedule[index].startTime = start
        customBlockingScheduleManagerObj.arrBlockingSchedule[index].endTime = end

        customBlockingScheduleManagerObj.updateCustomBlockingScheduleAtIndex(index)
        customBlockingScheduleManagerObj.saveBlockingSchedulesToLocal()
        customBlockingScheduleManagerObj.updateEditedBlockingScheduleEndTimeIfRunning(index: index)
        reload()
    }

    // MARK: Time conversion

    static func minutes(from hhmm: String) -> Int {
        let parts = hhmm.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
        return max(0, min(1440, h * 60 + m))
    }

    static func hhmm(fromMinutes minutes: Int) -> String {
        let clamped = max(0, min(1439, minutes))
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}
