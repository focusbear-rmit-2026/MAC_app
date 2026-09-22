//
//  BlockingScheduleEditorView.swift
//  Focus Bear
//
//  SwiftUI rebuild of the blocking-schedule editor (Figma editor screen):
//  name, segmented day-scope + day pills, a draggable time-range slider,
//  block-list dropdown, radio strictness, and a "More Options" disclosure.
//  Hosted by `blockingScheduleEditorVC`, which owns the save/overlap/block-list
//  logic the view calls back into.
//

import SwiftUI

struct FocusModeOption: Identifiable {
    let id: String
    let name: String
}

/// Localised strings for the blocking-schedule editor — config-driven with an English fallback,
/// mirroring `ScheduleText` / `FocusButtonText`. Keys live under `blockingScheduleEditorVcInfo` in
/// config.json (and the assets repo config.json / config-es.json).
enum BlockingScheduleEditorText {
    private static var info: NSDictionary? { configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary }
    private static func t(_ key: String, _ fallback: String) -> String {
        (info?.value(forKey: key) as? String) ?? fallback
    }
    /// The schedule's start–end window. Named "Blocking time" rather than "Active time" so it reads as
    /// "when blocking is on" instead of "when you are active" (report 2026-09-15_17-43-33).
    static var titleBlockingTime: String { t("titleBlockingTime", "Blocking time") }
}

/// What a BRAND NEW blocking schedule starts out as. Only ever applied when creating one — an
/// existing schedule is always loaded from its saved values, so changing these cannot rewrite
/// anybody's saved window or toggles.
enum BlockingScheduleDefaults {
    /// 08:00–17:00, a plausible workday, asked for in report 2026-09-15_17-43-33. The old "two minutes
    /// from now, for an hour" made onboarding create a block that expired the same morning.
    static let startMinutes = 8 * 60
    static let endMinutes = 17 * 60
    /// Both off by default: the PO wants a new user to opt IN to AI relevance checking and to losing
    /// microbreaks, rather than discover them already ticked (adjusts the defaults set by #2304).
    static let isAIEnabled = false
    static let skipMicroBreaks = false
    static let strictness: FOCUSMODESTRICTNESS = ._NORMAL_
}

// MARK: - View model

@available(macOS 11.0, *)
final class BlockingScheduleEditorModel: ObservableObject {
    @Published var name = ""
    @Published var emoji: String?
    @Published var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]   // 1=Sun ... 7=Sat
    @Published var startMinutes = BlockingScheduleDefaults.startMinutes
    @Published var endMinutes = BlockingScheduleDefaults.endMinutes
    @Published var focusModes: [FocusModeOption] = []
    @Published var selectedFocusModeID: String?
    @Published var strictness: FOCUSMODESTRICTNESS = BlockingScheduleDefaults.strictness
    @Published var useAI = BlockingScheduleDefaults.isAIEnabled
    @Published var skipMicroBreaks = BlockingScheduleDefaults.skipMicroBreaks
    @Published var isEditing = false

    /// Seed the editor for a NEW schedule. Times can be pre-filled (dragging a slot on the calendar,
    /// or picking a preset); anything not pre-filled falls back to `BlockingScheduleDefaults`.
    func applyNewScheduleDefaults(startMinutes: Int? = nil, endMinutes: Int? = nil) {
        isEditing = false
        self.startMinutes = startMinutes ?? BlockingScheduleDefaults.startMinutes
        self.endMinutes = endMinutes ?? BlockingScheduleDefaults.endMinutes
        if self.endMinutes <= self.startMinutes { self.endMinutes = min(1440, self.startMinutes + 60) }
        useAI = BlockingScheduleDefaults.isAIEnabled
        skipMicroBreaks = BlockingScheduleDefaults.skipMicroBreaks
    }

    /// Load an EXISTING schedule's saved window and toggles. Defaults never apply here — this is what
    /// keeps a user who already picked 9–6 (or ticked "skip microbreaks") seeing their own values.
    func applySavedSchedule(startMinutes: Int, endMinutes: Int, isAIBlockingEnabled: Bool, isMicroBreaksEnabled: Bool) {
        isEditing = true
        self.startMinutes = startMinutes
        // A cross-midnight window isn't representable on the slider; clamp it to the end of the day.
        let rawEnd = endMinutes <= startMinutes ? 1440 : endMinutes
        self.endMinutes = min(1440, max(startMinutes + 15, rawEnd))
        useAI = isAIBlockingEnabled
        skipMicroBreaks = !isMicroBreaksEnabled
    }

    func reloadFocusModes() {
        focusModes = arrFocusType.compactMap { fm in
            if fm["isMeetings"] as? Bool ?? false { return nil }
            guard let id = fm["id"] as? String else { return nil }
            return FocusModeOption(id: id, name: fm["name"] as? String ?? "")
        }
        if let current = selectedFocusModeID, focusModes.contains(where: { $0.id == current }) { return }
        selectedFocusModeID = focusModes.first?.id
    }
}

// MARK: - Editor view

@available(macOS 11.0, *)
struct BlockingScheduleEditorView: View {
    @ObservedObject var model: BlockingScheduleEditorModel
    var onSave: () -> Void
    var onCancel: () -> Void
    var onDelete: () -> Void
    var onEditBlockList: () -> Void
    var onBack: () -> Void
    // Onboarding reuses this editor to create the very first blocking schedule, where there is
    // deliberately no block-list picker (the user hasn't set up any focus modes yet). Default true
    // keeps the in-app Settings editor unchanged; onboarding passes false to hide the Block-list row.
    var showBlockList: Bool = true
    // Onboarding overlays its own step-progress indicator on top of this editor and has no
    // back/cancel affordance, so it hides the editor's own header + Cancel button. Defaults keep the
    // in-app Settings editor unchanged.
    var showHeader: Bool = true
    var showCancel: Bool = true
    // Onboarding keeps the storyboard's own "Add Block" CTA and hides the editor's footer entirely.
    var showFooter: Bool = true
    // Onboarding showed the AI / skip-microbreaks toggles directly (no collapsed section), so it opens
    // the "More Options" group by default.
    var expandMoreOptions: Bool = false
    // Onboarding runs in a much wider window than the Settings pane, where a full-bleed content column
    // looks stretched. When set, the scrolling content is capped to this width and centered. nil keeps
    // the in-app editor full-width as before.
    var contentMaxWidth: CGFloat? = nil

    @SwiftUI.State private var showMoreOptions = false

    // Day pills in display order Sun…Sat with their weekday index.
    private let dayPills: [(label: String, index: Int)] = [
        ("S", 1), ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if showHeader { header }
            ScrollView {
                VStack(spacing: 16) {
                    scheduleCard
                    blockListCard
                    moreOptions
                    if showFooter { footer }
                }
                .padding(20)
                .frame(maxWidth: contentMaxWidth ?? .infinity)   // cap + center the column (onboarding)
                .frame(maxWidth: .infinity)                       // outer fills width so the cap centers
            }
        }
        .background(FBColor.background)
        .onAppear { if expandMoreOptions { showMoreOptions = true } }
    }

    private var header: some View {
        BlockingScheduleHeader(title: model.isEditing ? "Edit blocking schedule" : "New blocking schedule",
                               onBack: onBack)
    }

    // MARK: Name + schedule + time

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            field(title: "Name") {
                HStack(spacing: 8) {
                    TextField("Create a block name", text: $model.name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.fbRegular(14))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(FBColor.fieldBackground))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FBColor.grayBorder, lineWidth: 1))
                    emojiPicker
                }
            }

            field(title: "Schedule") {
                VStack(alignment: .leading, spacing: 10) {
                    dayScopeSegmented
                    dayPillRow
                }
            }

            field(title: BlockingScheduleEditorText.titleBlockingTime) {
                VStack(spacing: 8) {
                    HStack {
                        timeChip(model.startMinutes)
                        Text("–").foregroundColor(.secondary)
                        timeChip(model.endMinutes)
                        Spacer()
                    }
                    TimeRangeSlider(startMinutes: $model.startMinutes, endMinutes: $model.endMinutes)
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    private let emojiChoices = ["🧠", "🌅", "🌙", "⚡️", "🏕️", "🛠️", "🎯", "😎", "💪", "📵", "💻", "📚", "🎨", "🏋️", "🧘"]

    private var emojiPicker: some View {
        Menu {
            SwiftUI.Button("None") { model.emoji = nil }
            ForEach(emojiChoices, id: \.self) { e in
                SwiftUI.Button(e) { model.emoji = e }
            }
        } label: {
            Text(model.emoji ?? "🙂")
                .font(.system(size: 18))
                .frame(width: 40, height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(FBColor.fieldBackground))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FBColor.grayBorder, lineWidth: 1))
                .opacity(model.emoji == nil ? 0.5 : 1)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
        .pointingHandCursor()
    }

    private var dayScopeSegmented: some View {
        HStack(spacing: 0) {
            scopeButton("Weekdays", [2, 3, 4, 5, 6])
            scopeButton("Weekends", [1, 7])
            scopeButton("Everyday", [1, 2, 3, 4, 5, 6, 7])
        }
        // Clip the row to the parent's rounded rect so a selected first/last option's fill picks up
        // the matching rounded outer corners and never pokes past the border. The middle option is
        // away from the corners, so it's unaffected.
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FBColor.grayBorder, lineWidth: 1))
    }

    private func scopeButton(_ title: String, _ days: Set<Int>) -> some View {
        let selected = model.selectedDays == days
        return SwiftUI.Button(action: { model.selectedDays = days }) {
            Text(title)
                .font(.fbMedium(12))
                .foregroundColor(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(selected ? FBColor.accent : Color.clear)
        }
        .buttonStyle(FBButtonStyle())
    }

    private var dayPillRow: some View {
        HStack(spacing: 6) {
            ForEach(dayPills, id: \.index) { pill in
                let on = model.selectedDays.contains(pill.index)
                SwiftUI.Button(action: { toggleDay(pill.index) }) {
                    Text(pill.label)
                        .font(.fbSemibold(13))
                        .foregroundColor(on ? .white : .primary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(on ? FBColor.accent : FBColor.lightOrangeBackground.opacity(0.5)))
                        .overlay(Circle().strokeBorder(on ? Color.clear : FBColor.grayBorder, lineWidth: 1))
                }
                .buttonStyle(FBButtonStyle())
            }
        }
    }

    // MARK: Block list + strictness

    private var blockListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showBlockList {
            field(title: "Block list") {
                HStack(spacing: 10) {
                    Menu {
                        ForEach(model.focusModes) { fm in
                            SwiftUI.Button(fm.name) { model.selectedFocusModeID = fm.id }
                        }
                    } label: {
                        Text(selectedFocusModeName)
                            .font(.fbRegular(13))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    // Padding/width/border all go on the Menu itself, not the label: the label is
                    // clamped to the menu style's fixed control height (so label padding doesn't grow
                    // the box) and its frame/border are ignored under BorderlessButtonMenuStyle.
                    // 3pt padding on all sides gives the box its full height + breathing room.
                    .padding(3)
                    // Enforce a 150pt minimum width, then fixedSize so it settles at that minimum
                    // instead of hugging the selected name — a consistent box regardless of the item.
                    .frame(minWidth: 150, alignment: .leading)
                    .fixedSize()
                    // Border/background wrap the padded box; small corner radius (5) for less-rounded
                    // corners. Overlay draws on top so the border is guaranteed visible.
                    .background(RoundedRectangle(cornerRadius: 5).fill(FBColor.fieldBackground))
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.gray.opacity(0.7), lineWidth: 1))
                    .pointingHandCursor()

                    SwiftUI.Button(action: onEditBlockList) {
                        // Hyperlink-style: accent-coloured, underlined text (no button chrome).
                        Text("Edit block list")
                            .font(.fbMedium(12))
                            .foregroundColor(FBColor.accent)
                            .underline()
                    }
                    .buttonStyle(FBButtonStyle())
                    .fixedSize()

                    Spacer(minLength: 0)       // keep the dropdown + link left-aligned
                }
            }
            }

            field(title: "Strictness") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 18) {
                        strictnessRadio("Flexible", ._NORMAL_)
                        strictnessRadio("Moderate", ._STRICT_)
                        strictnessRadio("Strict", ._SUPER_STRICT_)
                        Spacer()
                    }
                    Text(strictnessDescription)
                        .font(.fbRegular(11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    private func strictnessRadio(_ title: String, _ value: FOCUSMODESTRICTNESS) -> some View {
        let on = model.strictness == value
        return SwiftUI.Button(action: { model.strictness = value }) {
            HStack(spacing: 6) {
                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(on ? FBColor.accent : .secondary)
                Text(title)
                    .font(.fbMedium(13))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(FBButtonStyle())
    }

    // MARK: More options

    private var moreOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUI.Button(action: { showMoreOptions.toggle() }) {
                HStack {
                    Text("More Options").font(.fbSemibold(14)).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showMoreOptions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
            }
            .buttonStyle(FBButtonStyle())

            if showMoreOptions {
                // No "Use AI" toggle here: AI is a per-block-list setting, not per-schedule — a schedule
                // just runs its block list, whose is_ai_enabled governs AI (the runtime reads it from the
                // block list). model.useAI stays defaulted so the saved schedule's flag is harmless/ignored,
                // matching the hidden AppKit checkbox in blockingScheduleEditorVC.
                Toggle(isOn: $model.skipMicroBreaks) {
                    Text("Skip microbreaks during this block").font(.fbRegular(13))
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if model.isEditing {
                SwiftUI.Button(action: onDelete) {
                    // Same title colour as Cancel (.primary), not red.
                    Text("Delete schedule").fbOutlineButtonLabel(.primary)
                }
                .buttonStyle(FBButtonStyle())
            }
            Spacer()
            if showCancel {
                SwiftUI.Button(action: onCancel) {
                    Text("Cancel").fbOutlineButtonLabel(.primary)
                }
                .buttonStyle(FBButtonStyle())
            }
            SwiftUI.Button(action: onSave) {
                Text(model.isEditing ? "Save changes" : "Create")
                    .font(.fbSemibold(13)).foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(FBColor.accent))
            }
            .buttonStyle(FBButtonStyle())
        }
    }

    // MARK: Helpers

    private var strictnessDescription: String {
        switch model.strictness {
        case ._NORMAL_:       return "Flexible — stop focusing anytime, no questions asked."
        case ._STRICT_:       return "Moderate — a 15-second delay before you can stop a session."
        case ._SUPER_STRICT_: return "Strict — once you start, you can't stop until it ends."
        }
    }

    private var selectedFocusModeName: String {
        model.focusModes.first(where: { $0.id == model.selectedFocusModeID })?.name ?? "Select a block list"
    }

    private func toggleDay(_ index: Int) {
        if model.selectedDays.contains(index) { model.selectedDays.remove(index) }
        else { model.selectedDays.insert(index) }
    }

    private func timeChip(_ minutes: Int) -> some View {
        Text(displayTime(minutes))
            .font(.fbSemibold(13))
            .foregroundColor(.primary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(FBColor.lightOrangeBackground.opacity(0.5)))
    }

    private func displayTime(_ minutes: Int) -> String {
        let h24 = minutes / 60, m = minutes % 60
        let ampm = h24 < 12 ? "AM" : "PM"
        var h = h24 % 12; if h == 0 { h = 12 }
        return String(format: "%d:%02d %@", h, m, ampm)
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.fbSemibold(12)).foregroundColor(.secondary)
            content()
        }
    }
}

@available(macOS 11.0, *)
private extension View {
    func cardBackground() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(FBColor.lightOrangeBackground.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FBColor.lightOrangeBorder, lineWidth: 1))
    }
}

// MARK: - Dual-handle time-range slider

@available(macOS 11.0, *)
struct TimeRangeSlider: View {
    @Binding var startMinutes: Int
    @Binding var endMinutes: Int

    private let total = 1440
    private let handle: CGFloat = 20

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let usable = max(1, geo.size.width - handle)
                let sx = CGFloat(startMinutes) / CGFloat(total) * usable
                let ex = CGFloat(endMinutes) / CGFloat(total) * usable
                ZStack(alignment: .leading) {
                    // Clickable track: a click on the empty track moves whichever handle is nearer
                    // straight to the clicked position. Sits at the bottom of the ZStack so the
                    // handles' own drag gestures still win when a handle itself is grabbed; the track
                    // capsules disable hit-testing so clicks on them pass through to here.
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(trackClickGesture(usable: usable))
                    Capsule().fill(FBColor.grayBorder.opacity(0.35))
                        .frame(height: 6)
                        .padding(.horizontal, handle / 2)
                        .allowsHitTesting(false)
                    Capsule().fill(FBColor.accent)
                        .frame(width: max(0, ex - sx), height: 6)
                        .offset(x: sx + handle / 2)
                        .allowsHitTesting(false)
                    handleView.offset(x: sx)
                        .gesture(dragGesture(usable: usable, isStart: true))
                    handleView.offset(x: ex)
                        .gesture(dragGesture(usable: usable, isStart: false))
                }
                .frame(height: handle)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 24)

            HStack {
                Text("12AM"); Spacer()
                Text("6AM"); Spacer()
                Text("12PM"); Spacer()
                Text("6PM"); Spacer()
                Text("12AM")
            }
            .font(.fbRegular(9))
            .foregroundColor(.secondary)
        }
    }

    private var handleView: some View {
        Circle()
            .fill(Color.white)
            .frame(width: handle, height: handle)
            .overlay(Circle().strokeBorder(FBColor.accent, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
    }

    private func dragGesture(usable: CGFloat, isStart: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let raw = (value.location.x - handle / 2) / usable * CGFloat(total)
                let snapped = snap(Int(raw))
                if isStart {
                    startMinutes = max(0, min(endMinutes - 15, snapped))
                } else {
                    endMinutes = max(startMinutes + 15, min(total, snapped))
                }
            }
    }

    /// Click anywhere on the empty track → move whichever handle (start/end) is nearer to the
    /// clicked minute directly to that position (ties go to the start handle).
    private func trackClickGesture(usable: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                let raw = (value.location.x - handle / 2) / usable * CGFloat(total)
                let clicked = snap(max(0, min(total, Int(raw))))
                if abs(clicked - startMinutes) <= abs(clicked - endMinutes) {
                    startMinutes = max(0, min(endMinutes - 15, clicked))
                } else {
                    endMinutes = max(startMinutes + 15, min(total, clicked))
                }
            }
    }

    // Coarse snapping for slider drags; use the ±1-min steppers above for an exact minute.
    private func snap(_ minutes: Int) -> Int { Int((Double(minutes) / 5).rounded()) * 5 }
}
