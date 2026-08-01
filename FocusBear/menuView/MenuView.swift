//
//  MenuView.swift
//  Focus Bear
//
//  SwiftUI redesign of the menu-bar popover (replacing the storyboard-driven menuViewController
//  content). Built from the Figma "Sid Focus Bear Design" — a compact list: a header with icon
//  buttons, a primary Start/Focus area, then Breaks / Day Plan / Focus Tools as accordion rows
//  (collapsed by default, one open at a time) that expand inline on tap.
//
//  The AppKit menuViewController owns a MenuModel and populates it from existing app state; this
//  view only renders + fires callbacks. It reports its content height back so the host can size
//  the popover to fit (incl. when an accordion expands), so nothing is ever clipped.
//

import SwiftUI
import AppKit

/// Notifications posted by the audio recorder so the menu's voice UI can show progress/results.
enum VoiceEvents {
    static let permissionDenied = Notification.Name("fbVoicePermissionDenied")
    static let processing = Notification.Name("fbVoiceProcessing")
    static let transcript = Notification.Name("fbVoiceTranscript")
    static let actionDone = Notification.Name("fbVoiceActionDone")
    static let error = Notification.Name("fbVoiceError")
    /// A recording was started by the Focus Button (device mic press) rather than from the menu —
    /// the menu should surface itself in listening state so the flow isn't invisible.
    static let deviceListening = Notification.Name("fbVoiceDeviceListening")
}

/// Menu strings, resolved from the app config (`menuView` section in the assets `config.json`,
/// keyed per language) with an English fallback so the code is i18n-ready before translations land.
func menuLocalized(_ key: String, _ fallback: String) -> String {
    if let dict = configjson.value(forKey: "menuView") as? NSDictionary,
       let s = dict.value(forKey: key) as? String, !s.isEmpty {
        return s
    }
    return fallback
}

/// Time-Tracker "today" view strings, resolved from the `timeTrackerViewInfo` config section (keyed
/// per language) with an English fallback. Kept separate from `menuLocalized`/`menuView` so the
/// Time-Tracker view's copy lives in its own dictionary rather than being mixed into the menu's.
func ttLocalized(_ key: String, _ fallback: String) -> String {
    if let dict = configjson.value(forKey: "timeTrackerViewInfo") as? NSDictionary,
       let s = dict.value(forKey: key) as? String, !s.isEmpty {
        return s
    }
    return fallback
}

// MARK: - Design system

@available(macOS 11.0, *)
enum MenuTheme {
    static let orange = Color(hex: 0xDE7400)
    static let cream = Color(hex: 0xFFEDC9)
    static let darkBg = Color(hex: 0x18181B)
    static let darkCard = Color(hex: 0x27272A)

    static func background(_ s: ColorScheme) -> Color { s == .dark ? darkBg : .white }
    static func cardBg(_ s: ColorScheme) -> Color { s == .dark ? darkCard : .white }
    static func chipBg(_ s: ColorScheme) -> Color { s == .dark ? orange.opacity(0.22) : Color(hex: 0xFFF1DA) }
    static func border(_ s: ColorScheme) -> Color { s == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07) }
    static func primaryText(_ s: ColorScheme) -> Color { s == .dark ? .white : Color(hex: 0x18181B) }
    static func subtitle(_ s: ColorScheme) -> Color { primaryText(s).opacity(0.55) }
    static func iconButtonBg(_ s: ColorScheme) -> Color { s == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.05) }

    // Use the app's SELECTED font (respects the user's font / accessibility choice).
    static func font(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        let nsFont: NSFont
        switch weight {
        case .regular:  nsFont = getRegularFont(size: size)
        case .medium:   nsFont = getMediumFont(size: size)
        case .semibold: nsFont = getSemiBoldFont(size: size)
        case .bold:     nsFont = getBoldFont(size: size)
        }
        return Font(nsFont)
    }
    enum Weight { case regular, medium, semibold, bold }
}

@available(macOS 11.0, *)
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

// MARK: - View model

@available(macOS 11.0, *)
final class MenuModel: ObservableObject {
    @Published var focusRunning = false
    @Published var focusPaused = false
    @Published var focusTaskTitle = ""
    var onSaveIntention: (String) -> Void = { _ in }   // edit the running focus session's intention
    @Published var focusOnTaskText = ""
    @Published var focusRemaining = ""
    @Published var focusedTodayText = ""

    @Published var breaksSummary = ""       // subtitle: "Next break in 28 minutes"
    @Published var lastBreakText = ""       // expanded body: "Last break 5m ago"
    // Whether the "Start a break now" button is offered (mirrors the legacy boxStartBreak gate).
    @Published var canStartBreak = false

    // Currently-playing habit (replaces the Start Focus button while a habit runs)
    @Published var habitPlaying = false
    @Published var habitName = ""
    @Published var habitTimer = ""
    /// For non-timer habits (those with a completion requirement), the requirement text to show in
    /// place of the countdown — their duration is a 24h fallback that would otherwise read ~23:59:59.
    @Published var habitCompletionRequirement = ""
    var onSkipHabit: () -> Void = {}
    var onPostponeHabit: () -> Void = {}
    @Published var dayPlanDate = ""             // "Tuesday, June 25" (collapsed subtitle)
    @Published var dayPlanNextEventTitle = ""   // next calendar event title (may be empty)
    @Published var dayPlanNextEventTime = ""    // its start time, e.g. "5:00 PM"
    @Published var dayPlanNextEventRelative = "" // "in 40 min"
    @Published var dayPlanNextHabit = ""    // next habit (raw, no prefix) or "Evening Routine starts at 5pm"
    @Published var nextHabitStartable = false // show the "Start" button only when habits are postponed
    @Published var habitsPostponedUntil = ""  // "Habits postponed until 10:07 PM" while a routine is postponed; empty otherwise
    @Published var dayPlanTasks: [DayPlanMenuTask] = []

    // Focus music
    @Published var musicTrackName = ""      // non-empty when a track is loaded (playing or paused)
    @Published var musicPlaying = false

    // Voice/mic is only offered to trial/subscription users.
    @Published var micAvailable = true

    // #2081: trial / expired subscription status shown at the top of the menu. Empty for paid users.
    @Published var subscriptionStatus = ""      // "Trial version - N of 21 trial days remaining" / "…expired"
    @Published var subscriptionExpired = false  // style red + warning icon when the trial/subscription has ended
    var onUpgrade: () -> Void = {}              // tap the status → open the Upgrade Now window

    // "Set up distraction blocking" banner — shown when no blocking schedule exists.
    @Published var showBlockingBanner = false
    var onSetUpBlocking: () -> Void = {}
    var onDismissBlocking: () -> Void = {}   // persist the "Remove" dismissal so the card stays hidden

    // Active blocking-schedule card (name + day/time + pause/resume toggle) — restores info the old
    // menu showed.
    @Published var blockingScheduleActive = false
    @Published var blockingScheduleName = ""
    @Published var blockingScheduleTime = ""
    @Published var blockingSchedulePaused = false
    var onToggleBlockingSchedule: () -> Void = {}
    var onOpenBlockingScheduleConfig: () -> Void = {}   // tap the card → blocking-schedule settings

    // Voice screen state
    @Published var inVoiceMode = false
    @Published var voicePermissionDenied = false
    @Published var voiceStatus: VoiceStatus = .listening
    @Published var voiceTranscript = ""
    @Published var voiceResult = ""          // action description or error message

    var onMic: () -> Void = {}              // start voice recording
    var onStopRecording: () -> Void = {}    // stop + transcribe + act
    var onCancelRecording: () -> Void = {}  // stop + discard
    var onOpenMicSettings: () -> Void = {}  // open System Settings → Microphone
    var onShowStats: () -> Void = {}        // "How's my focus today?"
    var onToggleMusic: () -> Void = {}
    var onToggleTask: (String) -> Void = { _ in }   // task id
    var onStartNextHabit: () -> Void = {}
    var onStartFocus: () -> Void = {}

    // Inline focus starter — the Start button expands into a duration stepper (+/-, hold to change a
    // lot), an intention field and a block-list picker, then starts the session directly.
    @Published var focusMinutes: Int = 15               // defaults to the last session's duration
    @Published var focusStarterExpanded = false         // tap once to reveal intention + block list, tap again to start
    @Published var focusIntentionDraft = ""
    @Published var focusBlockLists: [MenuBlockList] = [] // choosable block lists / focus modes
    @Published var selectedBlockListId = ""
    var onStartFocusConfigured: (Int, String, String) -> Void = { _, _, _ in }   // minutes, intention, blockListId
    var onStopFocus: () -> Void = {}
    var onPauseFocus: () -> Void = {}
    var onResumeFocus: () -> Void = {}
    // Whether the running session can be paused (only timed sessions can — mirrors the legacy
    // `timerForFocusMode != nil` gate). Hides the Pause button for open-ended sessions.
    @Published var focusPausable = false
    var onOpenBreaks: () -> Void = {}
    var onOpenDayPlan: () -> Void = {}
    var onOpenFocusMusic: () -> Void = {}
    var onOpenBrainDump: () -> Void = {}
    var onOpenToDoPlayer: () -> Void = {}
    var onPreferences: () -> Void = {}
    var onQuit: () -> Void = {}
    var onTogglePin: () -> Void = {}            // switch the menu between popover and window (pinned) mode
    @Published var menuPinnedAsWindow = false   // true = shown as a detached window; false = popover
}

struct DayPlanMenuTask: Identifiable {
    let id: String
    let title: String
    let done: Bool
}

struct MenuBlockList: Identifiable {
    let id: String
    let name: String
}

/// A +/- button that fires once on tap and then auto-repeats while held, accelerating the longer
/// you hold it — so you can change the focus duration by a lot with a press-and-hold.
@available(macOS 11.0, *)
private struct HoldRepeatButton: View {
    let systemName: String
    let action: () -> Void
    @SwiftUI.State private var timer: Timer?
    @SwiftUI.State private var interval: Double = 0.35
    @SwiftUI.State private var pressing = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 42, height: 30)
            .contentShape(Rectangle())
            .opacity(pressing ? 0.55 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressing else { return }
                        pressing = true
                        action()                       // immediate first step
                        interval = 0.35
                        scheduleNext()
                    }
                    .onEnded { _ in stop() }
            )
    }

    private func scheduleNext() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            action()
            interval = max(0.05, interval * 0.75)      // accelerate while held
            scheduleNext()
        }
    }

    private func stop() {
        pressing = false
        timer?.invalidate(); timer = nil
        interval = 0.35
    }
}

/// A typeahead block-list picker backed by AppKit's NSComboBox — type to autocomplete a block list
/// (or open the dropdown). Nicer than a plain menu when there are several lists.
@available(macOS 11.0, *)
struct BlockListComboBox: NSViewRepresentable {
    let items: [MenuBlockList]
    @Binding var selectedId: String

    func makeNSView(context: Context) -> NSComboBox {
        let box = NSComboBox()
        box.completes = true                 // typeahead autocomplete as you type
        box.isEditable = true
        box.usesDataSource = false
        box.isBordered = false
        box.drawsBackground = false
        box.focusRingType = .none
        box.font = .systemFont(ofSize: 13)
        box.numberOfVisibleItems = 8
        box.delegate = context.coordinator
        box.placeholderString = "Block list"
        return box
    }

    func updateNSView(_ box: NSComboBox, context: Context) {
        context.coordinator.parent = self
        let names = items.map { $0.name }
        if (box.objectValues as? [String]) != names {
            box.removeAllItems()
            box.addItems(withObjectValues: names)
        }
        if let name = items.first(where: { $0.id == selectedId })?.name, box.stringValue != name {
            box.stringValue = name
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: BlockListComboBox
        init(_ parent: BlockListComboBox) { self.parent = parent }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let box = notification.object as? NSComboBox else { return }
            // The selection isn't reflected in stringValue until the run loop turns; read the index next tick.
            DispatchQueue.main.async {
                let idx = box.indexOfSelectedItem
                if idx >= 0 && idx < self.parent.items.count {
                    self.parent.selectedId = self.parent.items[idx].id
                }
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let box = obj.object as? NSComboBox else { return }
            if let match = parent.items.first(where: { $0.name.caseInsensitiveCompare(box.stringValue) == .orderedSame }) {
                parent.selectedId = match.id
            }
        }
    }
}

enum VoiceStatus { case listening, processing, done, error }

// Reports the content height up to the AppKit host so it can size the popover to fit.
@available(macOS 11.0, *)
private struct MenuHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

// MARK: - Root view

@available(macOS 11.0, *)
struct FocusBearMenuView: View {
    @ObservedObject var model: MenuModel
    @Environment(\.colorScheme) private var scheme

    enum Section { case focus, breaks, dayPlan, tools }
    enum Mode { case menu, voice }
    @SwiftUI.State private var expanded: Section?
    @SwiftUI.State private var mode: Mode = .menu
    @SwiftUI.State private var blockingBannerDismissed = false
    @SwiftUI.State private var editingIntention = false
    @SwiftUI.State private var intentionDraft = ""

    static let width: CGFloat = 320

    /// Called with the measured content height whenever it changes (so the host resizes the popover).
    var onHeight: (CGFloat) -> Void = { _ in }
    /// Snapshot helper: open one section for the off-screen render.
    var initialExpanded: Section?
    /// Snapshot helper: start in voice mode.
    var initialMode: Mode = .menu

    var body: some View {
        // Top-align the content and fill whatever space the host gives us, so the header (settings
        // buttons) always sits at the very top — no centring, no top white-space — even before the
        // popover shrinks to the reported content height.
        VStack(spacing: 0) {
            if mode == .voice {
                VoiceView(model: model, scheme: scheme, onClose: {
                    model.onCancelRecording()
                    model.inVoiceMode = false
                    mode = .menu
                })
            } else {
                measuredContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)   // natural height — never maxHeight:.infinity (feedback loop)
        .background(MenuTheme.background(scheme))
        .onPreferenceChange(MenuHeightKey.self) { onHeight($0) }
        .onChange(of: model.inVoiceMode) { active in
            // Mirror voice mode into the local screen state: ENTER the voice screen when a recording
            // starts and EXIT to the menu when it clears. Previously this only handled the exit (`if
            // !active`), so the DEVICE mic — which drives the voice UI purely via model.inVoiceMode (set
            // by the deviceListening observer), unlike the in-app mic's startVoice() which sets `mode`
            // directly — opened the menu but never switched to the voice screen.
            mode = active ? .voice : .menu
        }
        .onAppear {
            if expanded == nil { expanded = initialExpanded }
            // If a recording is already active when the popover appears (the device mic opened the menu),
            // start on the voice screen instead of the menu.
            mode = model.inVoiceMode ? .voice : initialMode
        }
    }

    private func startVoice() {
        model.inVoiceMode = true
        model.voicePermissionDenied = false
        model.voiceStatus = .listening
        model.voiceTranscript = ""
        model.voiceResult = ""
        model.onMic()
        mode = .voice
    }

    /// The accordion that currently shows the orange highlight: whichever one is open, or — when
    /// nothing is open — the Focus card while a focus session is running.
    private var highlightedSection: Section? {
        expanded ?? (model.focusRunning ? .focus : nil)
    }

    private var measuredContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if model.showBlockingBanner && !blockingBannerDismissed {
                BlockingBanner(scheme: scheme,
                               onSetUp: model.onSetUpBlocking,
                               onDismiss: { blockingBannerDismissed = true; model.onDismissBlocking() })
            }

            if model.focusRunning {
                focusAccordion
            } else if model.habitPlaying {
                habitCard
            } else {
                startButton
            }

            if model.blockingScheduleActive {
                blockingScheduleCard
            }

            AccordionRow(icon: "cup.and.saucer.fill",
                         title: menuLocalized("menuBreaks", "Breaks"),
                         subtitle: model.breaksSummary.isEmpty ? menuLocalized("menuTakeBreak", "Take a mindful break") : model.breaksSummary,
                         solid: highlightedSection == .breaks,
                         isOpen: binding(.breaks), scheme: scheme) {
                VStack(alignment: .leading, spacing: 8) {
                    if !model.lastBreakText.isEmpty {
                        Text(model.lastBreakText)
                            .font(MenuTheme.font(12, .regular))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                    }
                    if model.canStartBreak {
                        LinkButton(title: menuLocalized("menuStartBreak", "Start a break now"), scheme: scheme, action: model.onOpenBreaks)
                    }
                }
            }

            AccordionRow(icon: "calendar",
                         title: menuLocalized("menuDayPlan", "Day Plan"),
                         subtitle: dayPlanSubtitle,
                         solid: highlightedSection == .dayPlan,
                         isOpen: binding(.dayPlan), scheme: scheme) {
                dayPlanBody
            }

            AccordionRow(icon: "ellipsis",
                         title: menuLocalized("menuFocusTools", "Focus Tools"),
                         // When a focus-music track is loaded, surface it (and a pause control) at the
                         // top level so it's identifiable/pausable without opening the accordion.
                         subtitle: model.musicTrackName.isEmpty
                            ? menuLocalized("menuFocusToolsSubtitle", "Music, brain dump & to-dos")
                            : "♪ " + model.musicTrackName,
                         solid: highlightedSection == .tools,
                         accessory: model.musicTrackName.isEmpty ? nil : AnyView(
                            MusicToggleButton(playing: model.musicPlaying, scheme: scheme, action: model.onToggleMusic)
                         ),
                         isOpen: binding(.tools), scheme: scheme) {
                VStack(spacing: 8) {
                    if model.musicTrackName.isEmpty {
                        ToolButton(icon: "music.note", title: menuLocalized("menuFocusMusic", "Focus Music"), scheme: scheme, action: model.onOpenFocusMusic)
                    } else {
                        // A track is loaded: play/pause icon on the left + the track name.
                        ToolButton(icon: model.musicPlaying ? "pause.fill" : "play.fill",
                                   title: model.musicTrackName, scheme: scheme, action: model.onToggleMusic)
                    }
                    ToolButton(icon: "brain", title: menuLocalized("menuBrainDump", "Brain Dump"), scheme: scheme, action: model.onOpenBrainDump)
                    ToolButton(icon: "checklist", title: menuLocalized("menuToDoPlayer", "To-Do Player"), scheme: scheme, action: model.onOpenToDoPlayer)
                }
            }

            // #2081: trial / expired subscription status — shown at the bottom of the menu.
            if !model.subscriptionStatus.isEmpty {
                SubscriptionBanner(text: model.subscriptionStatus,
                                   expired: model.subscriptionExpired,
                                   scheme: scheme,
                                   onUpgrade: model.onUpgrade)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GeometryReader { g in
            Color.clear.preference(key: MenuHeightKey.self, value: g.size.height)
        })
    }

    private func binding(_ s: Section) -> Binding<Bool> {
        // No animation: animating the expand resizes the popover every frame, which feels laggy.
        Binding(get: { expanded == s }, set: { newVal in
            expanded = newVal ? s : nil
            // Opening any accordion also collapses the idle "Start Focus" starter — the mirror of how
            // tapping Start Focus collapses the accordions, so only one thing is ever open at a time.
            if newVal { model.focusStarterExpanded = false }
        })
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 8) {
            Text("Focus Bear")
                .font(MenuTheme.font(17, .bold))
                .foregroundColor(MenuTheme.primaryText(scheme))
            Spacer()
            if model.micAvailable {
                IconButton(systemName: "mic", scheme: scheme, action: startVoice)
            }
            IconButton(systemName: model.menuPinnedAsWindow ? "pin.fill" : "pin", scheme: scheme, action: model.onTogglePin)
            IconButton(systemName: "gearshape", scheme: scheme, action: model.onPreferences)
            IconButton(systemName: "power", scheme: scheme, action: model.onQuit)
        }
        .padding(.bottom, 2)
    }

    // MARK: Start button (idle)
    // Collapsed: a plain START FOCUS SESSION button. Tapping it expands the card to a "Focus Goal?"
    // + block-list box and a duration stepper; tapping the stepper (or ▶) then starts the session.
    private var startButton: some View {
        VStack(spacing: 8) {
            if model.focusStarterExpanded {
                // Focus Goal + block-list dropdown grouped together in one box.
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        TextField(menuLocalized("menuFocusGoalPlaceholder", "Enter Focus Goal here"),
                                  text: $model.focusIntentionDraft)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(MenuTheme.font(13, .regular))
                            .foregroundColor(MenuTheme.primaryText(scheme))
                        // Advanced (icon only): open the main window's Start Focus Session view for the
                        // full set of options. Reuses the existing onStartFocus action.
                        SwiftUI.Button(action: model.onStartFocus) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(MenuTheme.orange)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                        .help(menuLocalized("menuAdvancedFocus", "Advanced"))
                    }
                    .padding(10)
                    if !model.focusBlockLists.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text(menuLocalized("menuSelectFocusMode", "Select Focus Mode"))
                                .font(MenuTheme.font(11, .semibold))
                                .foregroundColor(MenuTheme.subtitle(scheme))
                            HStack(spacing: 8) {
                                Image(systemName: "shield.lefthalf.filled").foregroundColor(MenuTheme.orange)
                                // Typeahead combo box: type to autocomplete a block list, or open the dropdown.
                                BlockListComboBox(items: model.focusBlockLists, selectedId: $model.selectedBlockListId)
                                    .frame(height: 24)
                            }
                        }
                        .padding(10)
                    }
                }
                .background(MenuTheme.cardBg(scheme))
                .cornerRadius(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(MenuTheme.border(scheme), lineWidth: 1))
                .transition(.opacity)

                // Duration bar:  [ − ]   N MIN / TAP TO START   [ + ]   [ ▶ ]
                HStack(spacing: 0) {
                    HoldRepeatButton(systemName: "minus") { adjustFocusMinutes(-5) }
                    SwiftUI.Button(action: startFocusNow) {
                        VStack(spacing: 1) {
                            Text(String(format: menuLocalized("menuFocusMinutes", "%d MIN"), model.focusMinutes))
                                .font(MenuTheme.font(16, .bold))
                            Text(menuLocalized("menuTapToStart", "TAP TO START"))
                                .font(MenuTheme.font(9, .semibold)).tracking(0.5).opacity(0.9)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    HoldRepeatButton(systemName: "plus") { adjustFocusMinutes(5) }
                    SwiftUI.Button(action: startFocusNow) {
                        Image(systemName: "play.fill").font(.system(size: 13, weight: .bold))
                            .frame(width: 34).contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
                .padding(.vertical, 12)
                .background(MenuTheme.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: MenuTheme.orange.opacity(0.30), radius: 5, x: 0, y: 2)

                Text(menuLocalized("menuChangeTimeHint", "CHANGE THE TIME WITH + AND -"))
                    .font(MenuTheme.font(9, .semibold)).tracking(0.5)
                    .foregroundColor(MenuTheme.subtitle(scheme))
            } else {
                // Initial state: the plain button. Tapping it reveals the goal box + duration stepper.
                // Collapse any open accordion (Day Plan / Breaks / Tools) so the focus starter takes
                // over cleanly and nothing else keeps refreshing underneath it.
                SwiftUI.Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded = nil; model.focusStarterExpanded = true } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 12, weight: .bold))
                        Text(menuLocalized("menuStartFocus", "START FOCUS SESSION"))
                            .font(MenuTheme.font(14, .bold)).tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MenuTheme.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: MenuTheme.orange.opacity(0.30), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
            }
        }
    }

    private func adjustFocusMinutes(_ delta: Int) {
        model.focusMinutes = min(180, max(5, model.focusMinutes + delta))
    }

    private func startFocusNow() {
        expanded = nil                       // keep the other accordions collapsed when a session starts
        model.onStartFocusConfigured(model.focusMinutes, model.focusIntentionDraft, model.selectedBlockListId)
        model.focusStarterExpanded = false   // collapse back to the plain button for next time
    }

    // MARK: Habit-playing card (replaces Start Focus while a habit runs; Skip / Postpone inline)
    private var habitCard: some View {
        VStack(spacing: 10) {
            Text(model.habitName)
                .font(MenuTheme.font(15, .semibold))
                .foregroundColor(MenuTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
            if !model.habitTimer.isEmpty {
                Text(model.habitTimer)
                    .font(MenuTheme.font(30, .bold))
                    .foregroundColor(MenuTheme.orange)
            } else if !model.habitCompletionRequirement.isEmpty {
                // Non-timer habit: show what completes it instead of a meaningless 24h countdown.
                Text(model.habitCompletionRequirement)
                    .font(MenuTheme.font(15, .semibold))
                    .foregroundColor(MenuTheme.orange)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
            HStack(spacing: 8) {
                habitActionButton(menuLocalized("menuSkip", "Skip"), action: model.onSkipHabit)
                habitActionButton(menuLocalized("menuPostpone", "Postpone"), action: model.onPostponeHabit)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(MenuTheme.orange.opacity(scheme == .dark ? 0.18 : 0.10))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(MenuTheme.orange.opacity(0.3), lineWidth: 1))
    }

    /// Active blocking-schedule card: name + day/time + a Pause/Resume toggle. Shown whenever a
    /// custom blocking schedule is on or paused (the old menu surfaced this; the redesign dropped it).
    private var blockingScheduleCard: some View {
        HStack(spacing: 10) {
            // The icon + text region is a Button (reliable hit-testing inside the popover, unlike
            // .onTapGesture) that opens the blocking-schedule config. Pause/Resume is a SEPARATE
            // sibling button (not nested) so its tap toggles the schedule instead of opening settings.
            SwiftUI.Button(action: model.onOpenBlockingScheduleConfig) {
                HStack(spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 18))
                        .foregroundColor(model.blockingSchedulePaused ? MenuTheme.subtitle(scheme) : MenuTheme.orange)
                    // Title / name / time each on their own row. The title is fixed ("Blocking schedule
                    // active/paused") and scales down slightly rather than truncating ("…a…"); the name
                    // sits below it, and the day/time below that, wrapping so the full window shows.
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.blockingSchedulePaused
                             ? menuLocalized("menuBlockingSchedulePaused", "Blocking schedule paused")
                             : menuLocalized("menuBlockingScheduleActive", "Blocking schedule active"))
                            .font(MenuTheme.font(14, .semibold))
                            .foregroundColor(MenuTheme.primaryText(scheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if !model.blockingScheduleName.isEmpty {
                            Text(model.blockingScheduleName)
                                .font(MenuTheme.font(12, .regular))
                                .foregroundColor(MenuTheme.subtitle(scheme))
                                .lineLimit(1)
                        }
                        Text(model.blockingScheduleTime)
                            .font(MenuTheme.font(12, .regular))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

            SwiftUI.Button(action: model.onToggleBlockingSchedule) {
                Text(model.blockingSchedulePaused ? menuLocalized("menuResume", "Resume")
                                                  : menuLocalized("menuPause", "Pause"))
                    .font(MenuTheme.font(12, .semibold))
                    .foregroundColor(MenuTheme.orange)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(MenuTheme.orange.opacity(0.15))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .fixedSize()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(MenuTheme.cardBg(scheme))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(MenuTheme.orange.opacity(0.3), lineWidth: 1))
    }

    private func habitActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(MenuTheme.font(13, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(MenuTheme.cardBg(scheme))
                .foregroundColor(MenuTheme.primaryText(scheme))
                .cornerRadius(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(MenuTheme.border(scheme), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    // MARK: Focus accordion (running)
    private var focusAccordion: some View {
        AccordionRow(icon: "timer",
                     // Show the focus goal as the section title once one is set; fall back to "Focus".
                     title: model.focusTaskTitle.isEmpty ? menuLocalized("menuFocus", "Focus") : model.focusTaskTitle,
                     subtitle: focusSubtitle,
                     solid: highlightedSection == .focus,
                     isOpen: binding(.focus), scheme: scheme) {
            VStack(alignment: .leading, spacing: 8) {
                intentionEditor
                if !model.focusOnTaskText.isEmpty {
                    Text(model.focusOnTaskText)
                        .font(MenuTheme.font(12, .regular))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                }
                if !model.focusedTodayText.isEmpty {
                    Text(menuLocalized("menuFocusedToday", "Focused today") + ": \(model.focusedTodayText)")
                        .font(MenuTheme.font(12, .regular))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                }
                // Pause / Resume alongside Stop (#2148): the legacy menu offered "Pause Session" when
                // clicking Stop; the redesign dropped it and Stop ended the session outright. A paused
                // session shows Resume instead of Pause; open-ended (non-timed) sessions show neither.
                HStack(spacing: 8) {
                    if model.focusPaused {
                        habitActionButton(menuLocalized("menuResumeSession", "Resume session"),
                                          action: model.onResumeFocus)
                    } else if model.focusPausable {
                        habitActionButton(menuLocalized("menuPauseSession", "Pause session"),
                                          action: model.onPauseFocus)
                    }
                    SwiftUI.Button(action: model.onStopFocus) {
                        Text(menuLocalized("menuStopSession", "Stop session"))
                            .font(MenuTheme.font(13, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(MenuTheme.orange)
                            .foregroundColor(.white)
                            .cornerRadius(9)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
        }
    }

    /// The focus-session intention: tap it (dotted underline signals it's editable) to type a new one,
    /// confirm with the tick. Saving routes through onSaveIntention → updateFocusModeIntention.
    @ViewBuilder private var intentionEditor: some View {
        if editingIntention {
            HStack(spacing: 6) {
                TextField("", text: $intentionDraft, onCommit: saveIntention)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.primaryText(scheme))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(MenuTheme.orange.opacity(0.12))
                    .cornerRadius(6)
                SwiftUI.Button(action: saveIntention) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundColor(MenuTheme.orange)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .help(menuLocalized("menuSaveIntention", "Save"))
            }
        } else if !model.focusTaskTitle.isEmpty {
            SwiftUI.Button(action: { intentionDraft = model.focusTaskTitle; editingIntention = true }) {
                Text(model.focusTaskTitle)
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.primaryText(scheme))
                    .lineLimit(2)
                    .padding(.bottom, 2)
                    .overlay(
                        DashedUnderline()
                            .stroke(MenuTheme.orange.opacity(0.75),
                                    style: StrokeStyle(lineWidth: 1, dash: [2.5, 2.5]))
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .help(menuLocalized("menuEditIntention", "Edit intention"))
        }
    }

    private func saveIntention() {
        let trimmed = intentionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { model.onSaveIntention(trimmed) }
        editingIntention = false
    }

    private var focusSubtitle: String {
        model.focusRemaining.isEmpty
            ? menuLocalized("menuSessionRunning", "Session running")
            : "\(model.focusRemaining) " + menuLocalized("menuRemaining", "remaining")
    }

    // MARK: Day Plan body
    /// Collapsed-row subtitle: surface what's actually coming up (next event, else next habit) so the
    /// row is useful at a glance instead of just repeating "Day Plan"/the date. Falls back to the date,
    /// then "Day Plan". No new i18n key needed — the values are already localized upstream.
    private var dayPlanSubtitle: String {
        if !model.dayPlanNextEventTitle.isEmpty {
            let time = model.dayPlanNextEventTime.isEmpty ? "" : "  ·  \(model.dayPlanNextEventTime)"
            return model.dayPlanNextEventTitle + time
        }
        if !model.dayPlanNextHabit.isEmpty { return model.dayPlanNextHabit }
        return model.dayPlanDate.isEmpty ? menuLocalized("menuDayPlan", "Day Plan") : model.dayPlanDate
    }

    private let dpBlue = Color(hex: 0x3B82F6)

    private func dpChip(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(color.opacity(0.15))
            .frame(width: 34, height: 34)
            .overlay(Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(color))
    }

    private var dayPlanBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            // NEXT EVENT
            if !model.dayPlanNextEventTitle.isEmpty {
                HStack(spacing: 10) {
                    dpChip(icon: "calendar", color: dpBlue)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(menuLocalized("menuNextEventLabel", "NEXT EVENT"))
                            .font(MenuTheme.font(9, .semibold)).tracking(0.6)
                            .foregroundColor(dpBlue)
                        Text(model.dayPlanNextEventTitle)
                            .font(MenuTheme.font(14, .semibold))
                            .foregroundColor(MenuTheme.primaryText(scheme))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(model.dayPlanNextEventTime)
                            .font(MenuTheme.font(13, .semibold))
                            .foregroundColor(MenuTheme.primaryText(scheme))
                        if !model.dayPlanNextEventRelative.isEmpty {
                            Text(model.dayPlanNextEventRelative)
                                .font(MenuTheme.font(10, .regular))
                                .foregroundColor(MenuTheme.subtitle(scheme))
                        }
                    }
                }
            }

            // NEXT HABIT
            if !model.dayPlanNextHabit.isEmpty {
                HStack(spacing: 10) {
                    dpChip(icon: "arrow.triangle.2.circlepath", color: MenuTheme.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(menuLocalized("menuNextHabitLabel", "NEXT HABIT"))
                            .font(MenuTheme.font(9, .semibold)).tracking(0.6)
                            .foregroundColor(MenuTheme.orange)
                        Text(model.dayPlanNextHabit)
                            .font(MenuTheme.font(14, .semibold))
                            .foregroundColor(MenuTheme.primaryText(scheme))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    if model.nextHabitStartable {
                        SwiftUI.Button(action: model.onStartNextHabit) {
                            Text(menuLocalized("menuStart", "Start"))
                                .font(MenuTheme.font(12, .semibold))
                                .padding(.horizontal, 16).padding(.vertical, 6)
                                .background(Capsule().fill(MenuTheme.orange))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                    }
                }
            }

            // Habits postponed until <time> — shown while a morning/evening routine is postponed.
            if !model.habitsPostponedUntil.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                    Text(model.habitsPostponedUntil)
                        .font(MenuTheme.font(12, .regular))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                }
            }

            // TASKS FOR TODAY (uncompleted only)
            if !model.dayPlanTasks.isEmpty {
                Divider().padding(.vertical, 1)
                Text(menuLocalized("menuTasksForToday", "TASKS FOR TODAY"))
                    .font(MenuTheme.font(10, .semibold))
                    .foregroundColor(MenuTheme.subtitle(scheme))
                    .tracking(0.8)
                ForEach(model.dayPlanTasks) { task in
                    SwiftUI.Button(action: { model.onToggleTask(task.id) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "circle")
                                .font(.system(size: 15))
                                .foregroundColor(MenuTheme.subtitle(scheme))
                            Text(task.title)
                                .font(MenuTheme.font(13, .regular))
                                .foregroundColor(MenuTheme.primaryText(scheme))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }

            if model.dayPlanNextEventTitle.isEmpty && model.dayPlanNextHabit.isEmpty && model.dayPlanTasks.isEmpty {
                Text(menuLocalized("menuNothingScheduled", "Nothing scheduled right now"))
                    .font(MenuTheme.font(12, .regular))
                    .foregroundColor(MenuTheme.subtitle(scheme))
            }
            LinkButton(title: menuLocalized("menuViewFullDayPlan", "View full day plan"), scheme: scheme, action: model.onOpenDayPlan)
        }
    }
}

// MARK: - Voice command screen (mic)

@available(macOS 11.0, *)
private struct VoiceView: View {
    @ObservedObject var model: MenuModel
    let scheme: ColorScheme
    let onClose: () -> Void
    @SwiftUI.State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            header
            if model.voicePermissionDenied {
                permissionDenied
            } else {
                recording
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GeometryReader { g in
            Color.clear.preference(key: MenuHeightKey.self, value: g.size.height)
        })
        .onAppear { pulse = true }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Focus Bear")
                .font(MenuTheme.font(17, .bold))
                .foregroundColor(MenuTheme.primaryText(scheme))
            Spacer()
            IconButton(systemName: "house", scheme: scheme, action: onClose)
            IconButton(systemName: model.menuPinnedAsWindow ? "pin.fill" : "pin", scheme: scheme, action: model.onTogglePin)
            IconButton(systemName: "gearshape", scheme: scheme, action: model.onPreferences)
            IconButton(systemName: "power", scheme: scheme, action: model.onQuit)
        }
    }

    // MARK: Permission-denied state
    private var permissionDenied: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 34)).foregroundColor(MenuTheme.orange)
                .padding(.top, 10)
            Text(menuLocalized("voicePermTitle", "Microphone access needed"))
                .font(MenuTheme.font(15, .semibold))
                .foregroundColor(MenuTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(menuLocalized("voicePermBody", "Focus Bear needs microphone access to hear your voice commands. Turn it on in System Settings → Privacy & Security → Microphone."))
                .font(MenuTheme.font(12, .regular))
                .foregroundColor(MenuTheme.subtitle(scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            SwiftUI.Button(action: model.onOpenMicSettings) {
                Text(menuLocalized("voiceOpenSettings", "Open System Settings"))
                    .font(MenuTheme.font(14, .semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(MenuTheme.orange).foregroundColor(.white).cornerRadius(11)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            secondaryButton(menuLocalized("voiceBack", "Back"), action: onClose)
        }
        .padding(.top, 4)
    }

    // MARK: Recording / processing / result state
    private var recording: some View {
        VStack(spacing: 12) {
            Text(promptText)
                .font(MenuTheme.font(13, .regular))
                .foregroundColor(MenuTheme.subtitle(scheme))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            micArea.padding(.vertical, 4)

            if !model.voiceTranscript.isEmpty {
                Text("“\(model.voiceTranscript)”")
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.primaryText(scheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if (model.voiceStatus == .done || model.voiceStatus == .error) && !model.voiceResult.isEmpty {
                Text(model.voiceResult)
                    .font(MenuTheme.font(12, .medium))
                    .foregroundColor(model.voiceStatus == .error ? Color(hex: 0xD2453B) : MenuTheme.orange)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            switch model.voiceStatus {
            case .done, .error:
                primaryButton(menuLocalized("voiceDone", "Done")) { onClose() }
            case .listening:
                // Done = finish speaking → transcribe + act. Cancel = discard.
                primaryButton(menuLocalized("voiceDone", "Done")) { model.onStopRecording() }
                secondaryButton(menuLocalized("voiceCancel", "Cancel"), icon: "xmark") {
                    model.onCancelRecording(); onClose()
                }
            case .processing:
                secondaryButton(menuLocalized("voiceCancel", "Cancel"), icon: "xmark") {
                    model.onCancelRecording(); onClose()
                }
            }

            if model.voiceStatus == .listening {
                Divider().padding(.vertical, 2)
                Text(menuLocalized("voiceTrySaying", "TRY SAYING:"))
                    .font(MenuTheme.font(10, .semibold)).tracking(0.8)
                    .foregroundColor(MenuTheme.subtitle(scheme))
                    .frame(maxWidth: .infinity)
                suggestion(menuLocalized("voiceSuggestFocus", "Start a 25 minute focus session"), model.onStartFocus)
                suggestion(menuLocalized("voiceSuggestStats", "How's my focus today?"), model.onShowStats)
                suggestion(menuLocalized("voiceSuggestRemind", "Remind me to…"), model.onOpenToDoPlayer)
            }
        }
    }

    private var promptText: String {
        switch model.voiceStatus {
        case .listening: return menuLocalized("voicePrompt", "Tell me your plans for the day…")
        case .processing: return menuLocalized("voiceThinking", "Thinking…")
        case .done: return menuLocalized("voiceGotIt", "Got it!")
        case .error: return menuLocalized("voiceOops", "Hmm…")
        }
    }

    private var micArea: some View {
        SwiftUI.Button(action: {
            switch model.voiceStatus {
            case .listening: model.onStopRecording()             // stop → transcribe + act
            case .done, .error: restart()                        // tap to try again
            case .processing: break
            }
        }) {
            ZStack {
                Circle().fill(MenuTheme.orange.opacity(0.12)).frame(width: 96, height: 96)
                Circle().fill(MenuTheme.orange.opacity(0.22)).frame(width: 74, height: 74)
                    .scaleEffect(model.voiceStatus == .listening && pulse ? 1.12 : 1.0)
                    .animation(model.voiceStatus == .listening ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default, value: pulse)
                Circle().fill(MenuTheme.orange).frame(width: 56, height: 56)
                micGlyph
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    @ViewBuilder private var micGlyph: some View {
        switch model.voiceStatus {
        case .listening:
            Image(systemName: "mic.fill").font(.system(size: 22, weight: .medium)).foregroundColor(.white)
        case .processing:
            ProgressView().scaleEffect(0.8).colorScheme(.dark)
        case .done:
            Image(systemName: "checkmark").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
        case .error:
            Image(systemName: "arrow.clockwise").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
        }
    }

    private func restart() {
        model.voiceTranscript = ""
        model.voiceResult = ""
        model.voiceStatus = .listening
        model.onMic()
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(MenuTheme.font(14, .semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(MenuTheme.orange).foregroundColor(.white).cornerRadius(11)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    private func secondaryButton(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text(title).font(MenuTheme.font(13, .semibold)).tracking(0.3)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 11)
            .background(MenuTheme.cardBg(scheme))
            .foregroundColor(MenuTheme.primaryText(scheme))
            .cornerRadius(11)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(MenuTheme.border(scheme), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    private func suggestion(_ text: String, _ action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "quote.bubble.fill").font(.system(size: 13)).foregroundColor(MenuTheme.orange)
                Text(text)
                    .font(MenuTheme.font(12, .medium))
                    .foregroundColor(MenuTheme.primaryText(scheme))
                    .lineLimit(2)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundColor(MenuTheme.subtitle(scheme))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MenuTheme.cardBg(scheme))
            .cornerRadius(11)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(MenuTheme.border(scheme), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

// MARK: - "Set up distraction blocking" banner

@available(macOS 11.0, *)
private func menuBundledImage(_ name: String) -> NSImage? {
    if let img = NSImage(named: name) { return img }
    if let url = Bundle.main.url(forResource: name, withExtension: "png") { return NSImage(contentsOf: url) }
    return nil
}

@available(macOS 11.0, *)
/// #2081: trial / expired subscription status, styled like the other menu rows — a leading icon, an
/// "Upgrade Now" title, and the status as a small subtitle. The whole row taps through to Upgrade Now
/// (no separate link needed). The status text is systemRed when expired — matching the old menu's
/// lblTrialVersionInfo — but the row background stays neutral like every other row.
private struct SubscriptionBanner: View {
    let text: String          // status description (trial days remaining / expired) — shown as the subtitle
    let expired: Bool
    let scheme: ColorScheme
    let onUpgrade: () -> Void

    var body: some View {
        SwiftUI.Button(action: onUpgrade) {
            HStack(spacing: 12) {
                IconChip(systemName: "crown.fill", scheme: scheme, onSolid: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(menuLocalized("menuUpgradeNow", "Upgrade Now"))
                        .font(MenuTheme.font(14, .semibold))
                        .foregroundColor(MenuTheme.primaryText(scheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(text)
                        .font(MenuTheme.font(11, .regular))
                        .foregroundColor(expired ? .red : MenuTheme.subtitle(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                // Fill the remaining width so the status uses the whole line before wrapping (a trailing
                // Spacer instead would make this column hug its content and wrap the text early).
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(MenuTheme.cardBg(scheme)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MenuTheme.border(scheme), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

private struct BlockingBanner: View {
    let scheme: ColorScheme
    let onSetUp: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SwiftUI.Button(action: onSetUp) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0xFFEDC9))
                        if let bear = menuBundledImage("blocking_bear") {
                            Image(nsImage: bear).resizable().aspectRatio(contentMode: .fit).frame(width: 42, height: 42)
                        } else {
                            Text("🐻").font(.system(size: 28))
                        }
                    }
                    .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(menuLocalized("blockingBannerTitle", "Set up distraction blocking to protect your focus session"))
                            .font(MenuTheme.font(14, .semibold))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 4) {
                            Image(systemName: "timer").font(.system(size: 11, weight: .semibold))
                            Text(menuLocalized("blockingBannerTask", "3 MIN TASK"))
                                .font(MenuTheme.font(11, .semibold)).tracking(0.5)
                        }
                        .foregroundColor(Color(hex: 0xFFB661))
                    }
                    Spacer(minLength: 18)   // leave room for the close button
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

            SwiftUI.Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0xFFB661))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
        }
        .background(
            LinearGradient(colors: [Color(hex: 0x7A5733), Color(hex: 0x553D22)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xE48E24).opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Components

/// A single horizontal line drawn at the bottom of its rect — stroked with a dash pattern to make
/// the editable intention's dotted underline.
private struct DashedUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

@available(macOS 11.0, *)
@available(macOS 11.0, *)
private struct MusicToggleButton: View {
    let playing: Bool
    let scheme: ColorScheme
    let action: () -> Void
    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: playing ? "pause.fill" : "play.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(MenuTheme.orange)
                .frame(width: 30, height: 30)
                .background(MenuTheme.chipBg(scheme))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .help(playing ? menuLocalized("menuPauseMusic", "Pause music") : menuLocalized("menuPlayMusic", "Play music"))
    }
}

@available(macOS 11.0, *)
private struct AccordionRow<Body: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Bool = false
    var bgColor: Color? = nil
    var solid: Bool = false      // solid orange card with white text (used for the running Focus card)
    // Optional control shown in the header before the chevron (e.g. the focus-music play/pause button),
    // tappable without expanding the row.
    var accessory: AnyView? = nil
    @Binding var isOpen: Bool
    let scheme: ColorScheme
    @ViewBuilder var content: () -> Body

    private var titleColor: Color { solid ? .white : (accent ? MenuTheme.orange : MenuTheme.primaryText(scheme)) }
    private var subColor: Color { solid ? Color.white.opacity(0.9) : MenuTheme.subtitle(scheme) }

    var body: some View {
        VStack(spacing: 0) {
            // The entire padded header is one hit target (contentShape), so anywhere on the top
            // row toggles expand/collapse.
            SwiftUI.Button(action: { isOpen.toggle() }) {
                HStack(spacing: 12) {
                    IconChip(systemName: icon, scheme: scheme, onSolid: solid)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(MenuTheme.font(14, .semibold))
                            .foregroundColor(titleColor)
                        Text(subtitle)
                            .font(MenuTheme.font(12, .regular))
                            .foregroundColor(subColor)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    // The accessory is its own Button, so tapping it fires its action instead of
                    // toggling the row (nested buttons route the tap to the innermost on macOS).
                    if let accessory { accessory }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(subColor)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The orange "highlight" lives on the HEADER only, so the open accordion's body stays
                // a readable normal card. Collapsed, the header IS the whole card → fully orange.
                .background(solid ? (bgColor ?? MenuTheme.orange) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

            if isOpen {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.top, solid ? 11 : 0)   // breathing room below the orange header
                    .padding(.bottom, 13)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MenuTheme.cardBg(scheme))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(solid ? MenuTheme.orange : MenuTheme.border(scheme), lineWidth: 1))
        .shadow(color: Color.black.opacity(scheme == .dark ? 0 : (solid ? 0.12 : 0.05)), radius: solid ? 6 : 5, x: 0, y: 2)
    }
}

@available(macOS 11.0, *)
private struct IconChip: View {
    let systemName: String
    let scheme: ColorScheme
    var onSolid: Bool = false
    var body: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(onSolid ? Color.white.opacity(0.22) : MenuTheme.chipBg(scheme))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(onSolid ? .white : MenuTheme.orange)
            )
    }
}

@available(macOS 11.0, *)
private struct LinkButton: View {
    let title: String
    let scheme: ColorScheme
    let action: () -> Void
    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(MenuTheme.font(12, .semibold))
                .foregroundColor(MenuTheme.orange)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

@available(macOS 11.0, *)
private struct ToolButton: View {
    let icon: String
    let title: String
    let scheme: ColorScheme
    let action: () -> Void
    var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 14))
                    .foregroundColor(MenuTheme.orange).frame(width: 20)
                Text(title)
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.primaryText(scheme))
                Spacer()
            }
            .padding(.vertical, 9).padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MenuTheme.chipBg(scheme).opacity(0.5))
            .cornerRadius(9)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

@available(macOS 11.0, *)
private struct IconButton: View {
    let systemName: String
    let scheme: ColorScheme
    let action: () -> Void
    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MenuTheme.primaryText(scheme).opacity(0.7))
                .frame(width: 30, height: 30)
                .background(MenuTheme.iconButtonBg(scheme))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

// MARK: - Off-screen snapshot (dev self-check, no popover needed)

@available(macOS 13.0, *)
@MainActor
enum MenuSnapshot {
    static func renderIfRequested() {
        guard ProcessInfo.processInfo.environment["FB_SNAPSHOT_MENU"] == "1" else { return }
        let dir = ProcessInfo.processInfo.environment["FB_SNAPSHOT_DIR"] ?? NSTemporaryDirectory()
        render(running(), expand: .focus, to: dir + "/menu_running.png")
        render(idle(), expand: nil, to: dir + "/menu_idle.png")
        render(idle(), expand: .dayPlan, to: dir + "/menu_dayplan.png")
        let banner = idle(); banner.showBlockingBanner = true
        render(banner, expand: nil, to: dir + "/menu_banner.png")
        let habit = idle()
        habit.habitPlaying = true
        habit.habitName = "🎲 (STIM) Do numbers"
        habit.habitTimer = "16:20"
        render(habit, expand: nil, to: dir + "/menu_habit.png")
        render(idle(), expand: nil, mode: .voice, to: dir + "/menu_voice.png")
        let perm = idle(); perm.voicePermissionDenied = true
        render(perm, expand: nil, mode: .voice, to: dir + "/menu_voice_permission.png")
        let done = idle()
        done.voiceStatus = .done
        done.voiceTranscript = "Start a 25 minute focus session"
        done.voiceResult = "Starting a 25-minute focus session"
        render(done, expand: nil, mode: .voice, to: dir + "/menu_voice_done.png")
        renderTracker(access: true, to: dir + "/tracker_today.png")
        renderTracker(access: false, to: dir + "/tracker_upgrade.png")
        NSLog("[MenuSnapshot] wrote menu PNGs to \(dir)")
    }

    private static func renderTracker(access: Bool, to path: String) {
        let m = TodayTrackerViewModel()
        m.hasAccess = access
        m.isLoading = false
        m.updatedAt = "16:37"
        if access {
            m.summary = FBTTTodaySummary(totalSeconds: 8 * 3600 + 52 * 60,
                projects: [
                    FBTTSlice(label: "Break/rest", seconds: 3 * 3600 + 5 * 60, color: .blue),
                    FBTTSlice(label: "Focus Bear - coding", seconds: 78 * 60, color: .yellow),
                    FBTTSlice(label: "Systematic review", seconds: 35 * 60, color: .purple),
                    FBTTSlice(label: "Habits", seconds: 31 * 60, color: .green),
                ],
                apps: [
                    FBTTSlice(label: "iTerm2", seconds: 4 * 3600 + 14 * 60, color: nil),
                    FBTTSlice(label: "Google Chrome", seconds: 119 * 60, color: nil),
                ])
        }
        let renderer = ImageRenderer(content: FBTTTodayView(model: m).frame(width: 520, height: 600))
        renderer.scale = 2
        guard let img = renderer.nsImage,
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }

    private static func render(_ model: MenuModel, expand: FocusBearMenuView.Section?, mode: FocusBearMenuView.Mode = .menu, to path: String) {
        let renderer = ImageRenderer(content: FocusBearMenuView(model: model, initialExpanded: expand, initialMode: mode).frame(width: FocusBearMenuView.width))
        renderer.scale = 2
        guard let img = renderer.nsImage,
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }

    private static func running() -> MenuModel {
        let m = MenuModel()
        m.focusRunning = true
        m.focusTaskTitle = "systematic review"
        m.focusOnTaskText = "100% on task"
        m.focusRemaining = "00:13:43"
        m.focusedTodayText = "0h 35m"
        m.breaksSummary = "Last break 12m ago"
        m.dayPlanNextHabit = "Make bed"
        return m
    }

    private static func idle() -> MenuModel {
        let m = MenuModel()
        m.breaksSummary = "Last break 12m ago"
        m.dayPlanDate = "Tuesday, June 25"
        m.dayPlanNextEventTitle = "E call"
        m.dayPlanNextEventTime = "5:00 PM"
        m.dayPlanNextEventRelative = "in 40 min"
        m.dayPlanNextHabit = "Make bed"
        m.dayPlanTasks = [
            DayPlanMenuTask(id: "1", title: "DSCP? grant", done: false),
            DayPlanMenuTask(id: "2", title: "Look at MRFF carefully", done: false),
            DayPlanMenuTask(id: "3", title: "Send button to Aaron", done: false),
        ]
        return m
    }
}

// MARK: - Teach-the-shortcut toast (#2003)

/// Fixed width of the hint toast; the height hugs the message (1–2 lines).
private let shortcutHintToastWidth: CGFloat = 320

/// A menu action that has a configurable global shortcut we can teach the user about.
/// Resolves its feature name (localized, matching the menu button label) and the user's
/// currently-configured shortcut so the toast reflects the real, possibly-customised combo.
enum ShortcutTeachableAction {
    case focusMusic
    case brainDump
    case taskList
    case startFocus   // the "Advanced" button next to the Focus Goal — opens the Start Focus Session view

    var featureName: String {
        switch self {
        case .focusMusic: return menuLocalized("menuFocusMusic", "Focus Music")
        case .brainDump:  return menuLocalized("menuBrainDump", "Brain Dump")
        case .taskList:   return menuLocalized("menuToDoPlayer", "To-Do Player")
        case .startFocus: return menuLocalized("menuStartFocusSession", "Start Focus Session")
        }
    }

    var char: String {
        switch self {
        case .focusMusic: return SettingsManagerObject.focusMusicShortcutChar
        case .brainDump:  return SettingsManagerObject.brainDumpShortcutChar
        case .taskList:   return SettingsManagerObject.taskListShortcutChar
        case .startFocus: return SettingsManagerObject.startPomodoroShortcutChar
        }
    }

    var flagInts: [Int] {
        switch self {
        case .focusMusic: return SettingsManagerObject.focusMusicShortcutFlags
        case .brainDump:  return SettingsManagerObject.brainDumpShortcutFlags
        case .taskList:   return SettingsManagerObject.taskListShortcutFlags
        case .startFocus: return SettingsManagerObject.startPomodoroShortcutFlags
        }
    }

    /// Stable key used to throttle how often this action's hint is shown.
    fileprivate var throttleKey: String {
        switch self {
        case .focusMusic: return "focusMusic"
        case .brainDump:  return "brainDump"
        case .taskList:   return "taskList"
        case .startFocus: return "startFocus"
        }
    }
}

/// Shows a small transient toast that teaches the keyboard shortcut for a menu action the user
/// just triggered by CLICK. Call it only from the click entry points (the `@IBAction`s) — never
/// from the Carbon hotkey handlers — so users who already use the shortcut aren't nagged.
@available(macOS 11.0, *)
final class ShortcutHintToast {

    static let shared = ShortcutHintToast()
    private init() {}

    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    private static let displayDuration: TimeInterval = 4
    private static let throttleInterval: TimeInterval = 24 * 60 * 60   // at most once per action per day
    private static let lastShownKeyPrefix = "shortcutHintLastShown_"
    private static let configKey = "menuShortcutHint"
    private static let fallbackTemplate = "Try %1$@ next time to open %2$@"
    private static let screenEdgeInset: CGFloat = 16

    func teach(_ action: ShortcutTeachableAction) {
        // Nothing to teach if the user cleared this shortcut.
        guard !action.char.isEmpty, !action.flagInts.isEmpty else { return }
        guard shouldShow(action) else { return }
        markShown(action)

        let shortcut = HotkeyService.spokenString(char: action.char, flagInts: action.flagInts)
        let template = menuLocalized(ShortcutHintToast.configKey, ShortcutHintToast.fallbackTemplate)
        let message = String(format: template, shortcut, action.featureName)
        present(message: message)
    }

    // MARK: Throttle

    private func lastShownKey(_ action: ShortcutTeachableAction) -> String {
        ShortcutHintToast.lastShownKeyPrefix + action.throttleKey
    }

    private func shouldShow(_ action: ShortcutTeachableAction) -> Bool {
        let last = UserDefaults.standard.double(forKey: lastShownKey(action))
        guard last > 0 else { return true }
        return Date().timeIntervalSince1970 - last >= ShortcutHintToast.throttleInterval
    }

    private func markShown(_ action: ShortcutTeachableAction) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastShownKey(action))
    }

    // MARK: Presentation

    private func present(message: String) {
        dismiss()

        let hosting = NSHostingView(rootView: ShortcutHintToastView(message: message))
        // Size the panel to the card's natural height for this message instead of a fixed height —
        // a fixed 68pt left the hosting view's flexible SwiftUI frame stretching the borderless
        // panel into a tall empty box (#2003 follow-up). The card fixes its own width.
        let size = NSSize(width: shortcutHintToastWidth, height: hosting.fittingSize.height)
        hosting.frame = NSRect(origin: .zero, size: size)

        let toast = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        toast.isOpaque = false
        toast.backgroundColor = .clear
        toast.hasShadow = true
        // Sit above the menu — which is shown at the modal-panel level as a pinned window
        // (getViewControllersObject) or as a pop-up-menu-level popover — so the hint isn't hidden
        // behind it (was .floating, which is below both). Still below screen-saver / shielding levels,
        // so it can't cover critical system UI.
        toast.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        toast.isMovableByWindowBackground = false
        toast.ignoresMouseEvents = true
        toast.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        toast.contentView = hosting

        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let inset = ShortcutHintToast.screenEdgeInset
        let origin = NSPoint(x: visible.maxX - size.width - inset,
                             y: visible.maxY - size.height - inset)
        toast.setFrameOrigin(origin)
        toast.orderFrontRegardless()
        panel = toast

        let work = DispatchWorkItem { [weak self] in self?.dismiss() }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ShortcutHintToast.displayDuration, execute: work)
    }

    private func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        panel?.orderOut(nil)
        panel = nil
    }
}

/// The toast card itself — a compact rounded banner with a keyboard glyph and the hint text.
@available(macOS 11.0, *)
private struct ShortcutHintToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "command")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MenuTheme.orange)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: shortcutHintToastWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MenuTheme.orange.opacity(0.35), lineWidth: 1)
        )
    }
}
