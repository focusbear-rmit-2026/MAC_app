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

/// The "Focus Goal:" label — reuses the existing `popUpAddNewFocusGoalVcInfo.titleGoal` config string
/// (already translated), so no new localization key is needed.
func menuFocusGoalLabel() -> String {
    let fallback = "Focus Goal:"   // i18n-ignore: last-resort default; the real string comes from config
    if let dict = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary,
       let s = dict.value(forKey: "titleGoal") as? String, !s.isEmpty {
        return s
    }
    return fallback
}

/// The "goal can't be changed in super-strict mode" note — reuses the existing
/// `popUpAddNewFocusGoalVcInfo.cannotChangeIntentionInSuperStrictText` config string (already translated).
func menuCannotChangeGoalNote() -> String {
    let fallback = "Focus goal cannot be changed in super strict mode"   // i18n-ignore: config-backed default
    if let dict = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary,
       let s = dict.value(forKey: "cannotChangeIntentionInSuperStrictText") as? String, !s.isEmpty {
        return s
    }
    return fallback
}

/// An SF-Symbol icon backed by AppKit so hovering shows the app's INSTANT tooltip
/// (showTooltipWithOsTahoe) rather than SwiftUI's `.help`, which only appears after the slow system delay.
@available(macOS 11.0, *)
struct InstantTooltipIcon: NSViewRepresentable {
    let symbol: String
    let message: String
    var pointSize: CGFloat = 15
    var preferredEdge: NSRectEdge = .minY

    func makeNSView(context: Context) -> HoverTooltipIconView {
        HoverTooltipIconView(symbol: symbol, message: message, pointSize: pointSize, preferredEdge: preferredEdge)
    }
    func updateNSView(_ nsView: HoverTooltipIconView, context: Context) {
        nsView.message = message
    }
}

@available(macOS 11.0, *)
final class HoverTooltipIconView: NSImageView {
    var message: String
    private let preferredEdge: NSRectEdge

    init(symbol: String, message: String, pointSize: CGFloat, preferredEdge: NSRectEdge) {
        self.message = message
        self.preferredEdge = preferredEdge
        super.init(frame: .zero)
        let cfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(cfg)
        contentTintColor = .secondaryLabelColor
        imageScaling = .scaleNone
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }
    override func mouseEntered(with event: NSEvent) {
        showTooltipWithOsTahoe(sender: self, msg: message, preferredEdge: preferredEdge,
                               maxWidthVal: 230, autoCloseOnMouseExit: true)
    }
    override func mouseExited(with event: NSEvent) {
        closePopoverTooltipIfVisible()
    }
}

/// The app's INSTANT tooltip on any SwiftUI view, not just an icon.
///
/// `InstantTooltipIcon` above solves this for SF Symbols, and the reason it exists applies just as
/// much to truncated text: SwiftUI's `.help` only appears after the system's slow hover delay, which
/// is no use for "what does that cut-off goal actually say?" (report 2026-09-21_16-29-14).
///
/// A transparent overlay that reports hover but never takes a click — `hitTest` returns nil, so the
/// editable goal row underneath is still a working button. Tracking areas keep firing regardless,
/// which is what makes the two compatible.
@available(macOS 11.0, *)
struct InstantTooltipOverlay: NSViewRepresentable {
    let message: String
    var preferredEdge: NSRectEdge = .minY

    func makeNSView(context: Context) -> HoverTooltipOverlayView {
        HoverTooltipOverlayView(message: message, preferredEdge: preferredEdge)
    }
    func updateNSView(_ nsView: HoverTooltipOverlayView, context: Context) {
        nsView.message = message
    }
}

@available(macOS 11.0, *)
final class HoverTooltipOverlayView: NSView {
    var message: String
    private let preferredEdge: NSRectEdge

    init(message: String, preferredEdge: NSRectEdge) {
        self.message = message
        self.preferredEdge = preferredEdge
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Invisible to clicks. Without this the overlay would sit on top of the goal row and swallow
    /// the tap that opens it for editing.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }
    override func mouseEntered(with event: NSEvent) {
        guard !message.isEmpty else { return }
        showTooltipWithOsTahoe(sender: self, msg: message, preferredEdge: preferredEdge,
                               maxWidthVal: 320, autoCloseOnMouseExit: true)
    }
    override func mouseExited(with event: NSEvent) {
        closePopoverTooltipIfVisible()
    }
}

@available(macOS 11.0, *)
extension SwiftUI.View {
    /// Shows `message` the instant the pointer enters. No-op for an empty message.
    func instantTooltip(_ message: String, preferredEdge: NSRectEdge = .minY) -> some View {
        overlay(InstantTooltipOverlay(message: message, preferredEdge: preferredEdge))
    }
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

// MARK: - Why blocking is off

/// A specific, fixable blocking issue. #1978: users who skip the macOS
/// permission prompts end up with blocking silently doing nothing, and the menu never said why.
enum BlockingOffReason: String, CaseIterable {
    /// The whole app was deactivated / aborted — the "OFF" badge in the menu bar.
    case appDeactivated
    /// A confirmed macOS permission issue. Other blocking mechanisms can still work.
    case permissionsMissing
    /// No blocking schedule has ever been created.
    case noSchedule
    /// A schedule exists but the user paused it.
    case schedulePaused
    /// A schedule exists and isn't paused, but its day/time window doesn't cover right now.
    case noScheduleRightNow
    /// The macOS grants are in place, but no browser has been set up for blocking, so websites
    /// can't be blocked. Kept apart from `permissionsMissing`: the fix is the browser list, not the
    /// permissions wizard.
    case noBrowserEnabled
    /// A browser is set up, but the per-second "what is the active tab?" read has been failing, so
    /// no website can be checked at all (report 2026-09-11_16-56-33). Usually the browser has
    /// stopped answering AppleScript — quitting and reopening it restores the reads.
    case browserNotResponding

    /// The sentence shown under "Blocking is off".
    var explanation: String {
        switch self {
        case .appDeactivated:
            return menuLocalized("blockingOffDeactivated", "Focus Bear is deactivated, so nothing is being blocked.")
        case .permissionsMissing:
            return menuLocalized("blockingPermissionsLimited", "Some blocking features may be unavailable because a macOS permission is missing. Other blocking can continue.")
        case .noSchedule:
            return menuLocalized("blockingOffNoSchedule", "You haven't set up a blocking schedule yet.")
        case .schedulePaused:
            return menuLocalized("blockingOffPaused", "Your blocking schedule is paused.")
        case .noScheduleRightNow:
            return menuLocalized("blockingOffNoScheduleNow", "No blocking schedule covers right now, and no focus session is running.")
        case .noBrowserEnabled:
            return menuLocalized("blockingOffNoBrowser", "No browser is set up for blocking, so websites won't be blocked.")
        case .browserNotResponding:
            return menuLocalized("blockingOffBrowserNotResponding", "Your browser has stopped telling Focus Bear which page is open, so websites aren't being checked. Quitting and reopening the browser usually fixes it.")
        }
    }

    /// The button that takes the user to where this reason is fixed.
    var fixTitle: String {
        switch self {
        case .appDeactivated:    return menuLocalized("blockingOffFixDeactivated", "Reactivate Focus Bear")
        case .permissionsMissing: return menuLocalized("blockingOffFixPermissions", "Grant permissions")
        case .noSchedule:        return menuLocalized("blockingOffFixNoSchedule", "Set up blocking")
        case .schedulePaused:    return menuLocalized("blockingOffFixPaused", "Resume blocking")
        case .noScheduleRightNow: return menuLocalized("blockingOffFixNoScheduleNow", "Edit blocking schedules")
        case .noBrowserEnabled:  return menuLocalized("blockingOffFixNoBrowser", "Set up browsers")
        case .browserNotResponding: return menuLocalized("blockingOffFixBrowserNotResponding", "Check browser setup")
        }
    }
}

/// Permission/browser setup gaps do not establish that all blocking has stopped: browser-specific
/// Apple Events and the Firefox extension are independent of Accessibility and System Events.
enum BlockingStatusCardKind: Equatable {
    case off, attention

    init(reasons: [BlockingOffReason]) {
        self = reasons.contains { reason in
            switch reason {
            case .permissionsMissing, .noBrowserEnabled: return false
            default: return true
            }
        } ? .off : .attention

    }

    var title: String {
        self == .off
            ? menuLocalized("blockingOffTitle", "Blocking is off")
            : menuLocalized("blockingAttentionTitle", "Blocking needs attention")
    }
}

enum BlockingPermissionIssue: Equatable {
    case accessibility, systemEvents

    var explanation: String {
        switch self {
        case .accessibility:
            return menuLocalized("blockingAccessibilityLimited", "macOS reports that Accessibility access is missing. Full-screen window blocking may be affected; browser blocking can still work.")
        case .systemEvents:
            return menuLocalized("blockingSystemEventsLimited", "macOS reports that System Events access is missing. Some window controls may be affected; browser blocking can still work.")
        }
    }
}

struct BlockingPermissionHealth {
    var accessibilityGranted: Bool
    var systemEvents: BlockingPermissionsState

    var issues: [BlockingPermissionIssue] {
        var result: [BlockingPermissionIssue] = []
        if !accessibilityGranted { result.append(.accessibility) }
        if systemEvents == .missing { result.append(.systemEvents) }
        return result
    }

    var state: BlockingPermissionsState {
        if !issues.isEmpty { return .missing }
        return systemEvents
    }
}

/// What we actually know about the macOS grants blocking needs.
///
/// A read-only automation query can be inconclusive (for example, System Events is not running).
/// Old evidence also expires. Neither case warrants claiming that a permission is missing.
enum BlockingPermissionsState: Equatable {
    /// A check confirmed the grants are there.
    case granted
    /// macOS refused or reports that consent is required. A setup preference cannot establish this.
    case missing
    /// Not probed yet, or the probe was inconclusive. Never worth a claim either way.
    case unknown

    /// Read-only AEDeterminePermissionToAutomateTarget result. A target that isn't running,
    /// a timeout, and unexpected failures cannot establish a denied grant.
    static func automationAuthorizationStatus(_ status: Int32) -> Self {
        switch status {
        case 0: return .granted
        case -1743, -1744: return .missing // refused, or consent has not yet been granted
        default: return .unknown
        }
    }
}

/// One in-flight check, with monotonic expiry measured from when the observation began. A slow
/// completion must not turn old permission evidence into a fresh denial when the menu reopens.
struct BlockingPermissionProbeCache {
    static let refreshInterval: TimeInterval = 10
    static let validityInterval: TimeInterval = 30
    private var inFlightAt: TimeInterval?
    private var sampledAt: TimeInterval?
    private var sample: BlockingPermissionsState = .unknown

    mutating func begin(at now: TimeInterval) -> Bool {
        guard inFlightAt == nil else { return false }
        if let sampledAt = sampledAt, now >= sampledAt,
           now - sampledAt < Self.refreshInterval { return false }
        inFlightAt = now
        return true
    }

    mutating func complete(_ state: BlockingPermissionsState, startedAt: TimeInterval) {
        guard inFlightAt == startedAt else { return }
        inFlightAt = nil
        sampledAt = startedAt
        sample = state
    }

    func state(at now: TimeInterval) -> BlockingPermissionsState {
        guard let sampledAt = sampledAt, now >= sampledAt,
              now - sampledAt <= Self.validityInterval else { return .unknown }
        return sample
    }
}

/// Everything the reasons depend on, passed in rather than read from the app's globals so the
/// answer can be unit-tested. Built once per menu tick in `menuViewController`.
struct BlockingStatus {
    var isAppEnabled: Bool
    var permissions: BlockingPermissionsState
    /// Whether any browser has been set up for blocking. `true` when we can't tell (the store is
    /// missing or hasn't loaded) — an unread list is not evidence against the user.
    var isAnyBrowserEnabled: Bool
    var scheduleCount: Int
    var isAnyScheduleOn: Bool
    var isAnySchedulePaused: Bool
    /// Whether some schedule's day/time window covers this moment — which is a different question
    /// from `isAnyScheduleOn` (whether one has actually been switched on).
    var isAnyScheduleCoveringNow: Bool
    var isFocusSessionRunning: Bool
    /// Whether a routine (morning/evening/custom, or a micro break) is running. Routines block on
    /// their own AND make `isAnyScheduleOn` meaningless — see `offReasons`.
    var isRoutineRunning: Bool
    /// Whether the active-tab reads that every website check depends on have stopped answering.
    var isBrowserUrlReadFailing = false

    /// Known blocking issues, most severe first. Permission/browser-only issues use an attention
    /// headline because some blocking mechanisms can continue independently.
    ///
    /// A reason is only listed when the inputs actually establish it. Anything we can't determine
    /// — an unfinished permission probe, a schedule that covers now but isn't on — is left unsaid:
    /// silence is recoverable, but sending someone to fix a thing that isn't broken is not.
    var offReasons: [BlockingOffReason] {
        // A deactivated app is the whole story — the schedule gaps below are its consequence, and
        // listing them too would bury the one thing the user has to undo.
        guard isAppEnabled else { return [.appDeactivated] }
        var reasons: [BlockingOffReason] = []
        // Missing grants limit some blocking features even mid-session, so retain the warning.
        // `.unknown` says nothing: the probe is async and the menu renders before it lands.
        if permissions == .missing { reasons.append(.permissionsMissing) }
        // Granted permissions with no browser set up still means no website blocking — but it's a
        // gap in the browser list, not in the macOS grants, so it gets its own reason and its own fix.
        if permissions != .missing && !isAnyBrowserEnabled { reasons.append(.noBrowserEnabled) }
        // A browser that has stopped answering is a live failure of the thing the user set up, so
        // it is reported whether or not a schedule is on — the reads are what blocking runs on.
        if isAnyBrowserEnabled && isBrowserUrlReadFailing { reasons.append(.browserNotResponding) }
        // A running focus session blocks on its own, and so does a routine — which additionally
        // suppresses schedule activation while it runs (`checkCustomBlockingScheduleTime` skips
        // every routine state), so during one `isAnyScheduleOn` is false whatever the schedules say
        // and none of the gaps below can be concluded from it.
        if !isFocusSessionRunning && !isRoutineRunning && !isAnyScheduleOn {
            if scheduleCount == 0 {
                reasons.append(.noSchedule)
            } else if isAnySchedulePaused {
                reasons.append(.schedulePaused)
            } else if !isAnyScheduleCoveringNow {
                reasons.append(.noScheduleRightNow)
            }
            // A schedule covers right now yet none is on: real, but we can't name the cause from
            // here, and "no schedule covers right now" would be a plain falsehood. Say nothing.
        }
        return reasons
    }

    /// One line naming the inputs and the conclusion, for the debug log — so the next report of
    /// "it says blocking is off but it isn't" is answered by reading a log instead of the source.
    var logDescription: String {
        let reasons = offReasons.map(\.rawValue).joined(separator: ",")
        return "appEnabled=\(isAppEnabled) permissions=\(permissions) browserEnabled=\(isAnyBrowserEnabled) "
            + "schedules=\(scheduleCount) scheduleOn=\(isAnyScheduleOn) schedulePaused=\(isAnySchedulePaused) "
            + "scheduleCoversNow=\(isAnyScheduleCoveringNow) focusSession=\(isFocusSessionRunning) "
            + "routine=\(isRoutineRunning) urlReadFailing=\(isBrowserUrlReadFailing) "
            + "→ \(reasons.isEmpty ? "no confirmed blocking issue" : reasons)"
    }
}

// MARK: - View model

@available(macOS 11.0, *)
final class MenuModel: ObservableObject {
    @Published var focusRunning = false
    @Published var focusPaused = false
    @Published var focusTaskTitle = ""       // the focus goal / intention
    @Published var focusModeName = ""        // the running focus mode/block-list name (e.g. "Deep Work")
    @Published var focusGoalEditable = true  // false in super-strict mode — the goal can't be changed
    var onSaveIntention: (String) -> Void = { _ in }   // edit the running focus session's intention
    @Published var focusOnTaskText = ""
    @Published var focusRemaining = ""
    @Published var focusedTodayText = ""
    /// The task the running session is actually working on (the focus queue's active entry), so the
    /// menu answers "what am I meant to be doing?" without opening the focus screen.
    @Published var focusCurrentTaskTitle = ""
    /// False during a class session, where the teacher's frontend owns the checklist.
    @Published var focusTaskActionable = false
    var onCompleteCurrentTask: () -> Void = {}
    var onChangeTask: () -> Void = {}

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
    @Published var dayPlanNextHabit = ""    // next habit name (raw, no prefix); when nothing is startable it's the upcoming routine's first habit (a preview)
    @Published var nextHabitStartable = false // show the "Start" button only when the shown habit is startable right now (live/actionable or resumable-postponed routine)
    @Published var dayPlanRoutineStart = "" // when nothing is startable: "🌅 Morning Routine starts at 7:00 AM" (header only); empty while a routine is live/startable
    @Published var dayPlanCurrentHabit = "" // the habit currently in progress (header only); empty when no habit is running
    @Published var habitsPostponedUntil = ""  // "Habits postponed until 10:07 PM" while a routine is postponed; empty otherwise
    @Published var dayPlanTasks: [DayPlanMenuTask] = []

    // Inline quick-add for today's Day Plan: "+ Add task" expands into a one-line composer that
    // understands the Day Plan's own `#project` / `!priority` tokens plus a duration (see
    // `QuickAddTaskParser`). Enter adds and keeps the field open so several can be typed in a row.
    @Published var quickAddExpanded = false
    @Published var quickAddText = "" {
        // Every keystroke changes which projects match, so the highlight goes back to the best one.
        didSet { quickAddSuggestionIndex = 0 }
    }
    /// Existing project names, so a typed `#project` reuses their canonical casing in the preview.
    @Published var quickAddProjectNames: [String] = []
    /// Which `#project` suggestion Tab accepts. ↑/↓ move it; it always starts on the first (best) match.
    @Published var quickAddSuggestionIndex = 0
    /// An image pasted into the composer before the task exists. Attachments hang off a to-do, and a
    /// task being typed has none yet, so it waits here and is uploaded once the task has been minted.
    @Published var quickAddPastedImage: ToDoPastedImage?
    /// Set when the shortcut card's ✕ is clicked, purely so SwiftUI re-renders. Whether the card shows
    /// is re-read from the stored preference on every render rather than cached here, because this
    /// model is built before the signed-in user has been restored and the preference is per account.
    @Published private var quickAddShortcutCardClosed = false
    var showsQuickAddShortcutCard: Bool {
        !quickAddShortcutCardClosed && !TaskShortcutCardPreference.isDismissedForCurrentUser
    }
    func dismissQuickAddShortcutCard() {
        TaskShortcutCardPreference.dismissForCurrentUser()
        quickAddShortcutCardClosed = true
    }
    var onQuickAddTask: (String, ToDoPastedImage?) -> Void = { _, _ in }

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

    // Blocking health card: partial capability warnings must not claim that all blocking is off.
    @Published var blockingOffReasons: [BlockingOffReason] = []
    @Published var blockingPermissionIssues: [BlockingPermissionIssue] = []
    var onFixBlockingOff: (BlockingOffReason) -> Void = { _ in }

    // Re-join card (#2267):- shown when the student declined a class focus session that's still live and
    // no session is currently active. The "Join session" button re-joins it.
    @Published var classSessionJoinable = false
    @Published var classSessionName = ""
    var onJoinClassSession: () -> Void = {}

    // Voice screen state
    @Published var inVoiceMode = false
    @Published var voicePermissionDenied = false
    @Published var voiceStatus: VoiceStatus = .listening
    @Published var voiceTranscript = ""
    @Published var voiceResult = ""          // action description or error message

    /// Shared by the menu microphone and the global voice shortcut.
    func beginVoiceInput() {
        guard micAvailable else { return }
        guard !inVoiceMode || (voiceStatus != .listening && voiceStatus != .processing) else { return }
        inVoiceMode = true
        voicePermissionDenied = false
        voiceStatus = .listening
        voiceTranscript = ""
        voiceResult = ""
        onMic()
    }

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
    // #777: recompute the duration for the currently-selected focus mode when the starter expands, so it
    // defaults to that mode's last-used duration. Implemented in menuViewController (needs the mode data).
    var onFocusStarterExpanded: () -> Void = {}
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

/// The "Select Focus Mode" picker: type to narrow the list of block lists, or open the dropdown.
///
/// Backed by `searchableComboBox` — the app's shared type-to-filter combo box, also behind the
/// Create Task and Notes project pickers — rather than a bare `NSComboBox`. A plain `NSComboBox`
/// with `completes = true` only does *inline prefix completion inside the field editor*: it never
/// opens the menu as you type, and it never matches mid-name. So with lists called "Work — deep"
/// typing "deep" showed nothing at all, which read as the picker being broken
/// (report 2026-09-16_10-20-39). `searchableComboBox` substring-filters and pops the menu open on
/// every keystroke, which is the behaviour that was missing.
@available(macOS 11.0, *)
struct BlockListComboBox: NSViewRepresentable {
    let items: [MenuBlockList]
    @SwiftUI.Binding var selectedId: String

    private static let fontSize: CGFloat = 13
    private static let visibleItems = 8

    func makeNSView(context: Context) -> searchableComboBox {
        let box = searchableComboBox()
        box.usesDataSource = true            // the filtered list is the data source, not objectValues
        box.completes = true
        box.isEditable = true
        box.isBordered = false
        box.drawsBackground = false
        box.focusRingType = .none
        box.font = .systemFont(ofSize: BlockListComboBox.fontSize)
        box.hasVerticalScroller = true
        box.numberOfVisibleItems = BlockListComboBox.visibleItems
        box.placeholderString = "Block list"
        // searchableComboBox is its own delegate/data source — that is what filters the list and
        // expands the menu on each keystroke. The SwiftUI side listens through `customDelegate`.
        box.delegate = box
        box.dataSource = box
        (box.cell as? NSComboBoxCell)?.dataSource = box
        box.customDelegate = context.coordinator
        box.target = context.coordinator
        box.action = #selector(Coordinator.comboCommitted(_:))
        return box
    }

    func updateNSView(_ box: searchableComboBox, context: Context) {
        context.coordinator.parent = self
        let names = items.map { $0.name }
        // `currentEditor()` is non-nil only while the field has focus, i.e. the user is typing. The
        // menu model reassigns its block lists about once a second, so without this guard every
        // refresh would stamp the selection back over a half-typed name — the "typing 'Deep' reverted
        // to 'Meetings' letter by letter" bug this control family keeps rediscovering.
        let isEditing = box.currentEditor() != nil
        if box.items != names {
            box.items = names
            // Re-apply the in-progress query, so a list arriving mid-word doesn't silently re-expand
            // the menu to every block list.
            box.filterData(comboBox: box, selectedText: isEditing ? box.stringValue : "")
        }
        if let name = items.first(where: { $0.id == selectedId })?.name,
           BlockListComboBox.shouldOverwriteText(isEditing: box.currentEditor() != nil,
                                                 current: box.stringValue, selectedName: name) {
            box.stringValue = name
        }
    }

    /// The rule that stops a SwiftUI refresh overwriting what the user is typing, shared with every
    /// other combo-box wrapper — see `ComboBoxTextSync` for why it exists.
    static func shouldOverwriteText(isEditing: Bool, current: String, selectedName: String) -> Bool {
        ComboBoxTextSync.shouldOverwriteText(isEditing: isEditing, current: current, selectedName: selectedName)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Pure helper (tested without a window)

    /// Which block list the text in the field means. An exact name wins; otherwise text that narrows
    /// the list to exactly one match picks that one, which is what the user is looking at. Anything
    /// ambiguous — or empty — means "no answer", and the current selection is left alone rather than
    /// being cleared out from under them.
    static func resolve(text: String, items: [MenuBlockList]) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let exact = items.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return exact.id
        }
        let matches = items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        return matches.count == 1 ? matches[0].id : nil
    }

    final class Coordinator: NSObject, SearchableComboBoxDelegate {
        var parent: BlockListComboBox
        init(_ parent: BlockListComboBox) { self.parent = parent }

        /// Return pressed, or a row picked from the menu. `stringValue` isn't committed yet at this
        /// point, so the highlighted row is the reliable answer.
        @objc func comboCommitted(_ sender: NSComboBox) {
            guard let box = sender as? searchableComboBox else { return }
            let index = box.indexOfSelectedItem
            let picked = index >= 0 && index < box.filterdItems.count ? box.filterdItems[index] : box.stringValue
            commit(text: picked, in: box)
        }

        /// A row chosen from the open dropdown (mouse click or arrow keys) fires this — commit it
        /// immediately. Without it, picking a block list from the menu overlay never wrote the binding,
        /// so `comboCommitted`/`itemSelectedByUser` only ran on Return or when field editing ended — and
        /// a SwiftUI "TAP TO START" click doesn't end AppKit field editing first. The binding stayed on
        /// the pre-selected default, so a session started from the menu always used "Block super
        /// distracting sites" regardless of the pick (#2657). Mirrors searchableComboBox's own coordinator.
        func listSelectionChangedByUser(comboBox: searchableComboBox) {
            comboCommitted(comboBox)
        }

        /// Editing finished without a pick (the user clicked away). Their text is what they meant.
        func itemSelectedByUser(comboBox: searchableComboBox) {
            commit(text: comboBox.stringValue, in: comboBox)
        }

        /// Every keystroke, so the binding always means what the field visibly says — a SwiftUI button
        /// click doesn't end AppKit field editing, so a user who types a name and goes straight to
        /// "Start" would otherwise start the previous mode. Only the binding is written here, never
        /// `stringValue`: replacing the text mid-word is the other trap this control family avoids.
        func itemEditedByUser(comboBox: searchableComboBox) {
            guard let resolved = BlockListComboBox.resolve(text: comboBox.stringValue, items: parent.items),
                  parent.selectedId != resolved else { return }
            parent.selectedId = resolved
        }

        private func commit(text: String, in box: searchableComboBox) {
            guard let resolved = BlockListComboBox.resolve(text: text, items: parent.items),
                  let name = parent.items.first(where: { $0.id == resolved })?.name else { return }
            if box.stringValue != name { box.stringValue = name }
            if parent.selectedId != resolved { parent.selectedId = resolved }
        }
    }
}

/// The menu's inline quick-add task field. AppKit-backed because it needs three things SwiftUI on
/// macOS 11 can't give: programmatic first-responder focus (no `@FocusState` before macOS 12),
/// a Return that commits WITHOUT dismissing the popover, and an Escape that collapses the row
/// instead of closing the popover (the field consumes `cancelOperation` before the popover sees it).
@available(macOS 11.0, *)
struct QuickAddTaskField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onCommit: () -> Void
    let onCancel: () -> Void
    /// Tab: accept the highlighted `#project` suggestion. Returns false when there is nothing to
    /// accept, so Tab keeps its usual "move to the next control" meaning.
    let onAcceptProjectSuggestion: () -> Bool
    /// ↑/↓: move the highlight within the suggestion list. Returns false when there is no list to move in.
    let onMoveProjectSuggestion: (Int) -> Bool

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 13)
        field.lineBreakMode = .byTruncatingTail
        field.cell?.usesSingleLineMode = true
        field.cell?.wraps = false
        field.delegate = context.coordinator
        field.stringValue = text
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text { field.stringValue = text }
        if field.placeholderString != placeholder { field.placeholderString = placeholder }
        // The field is only ever mounted while the row is expanded, so taking focus once on mount is
        // exactly "focus when the user opens the composer".
        guard !context.coordinator.didTakeFocus, let window = field.window else { return }
        context.coordinator.didTakeFocus = true
        DispatchQueue.main.async {
            // The menu can be hosted in a window that isn't key yet — the full-screen overlay panel is
            // deliberately `becomesKeyOnlyIfNeeded`, and the popover is shown without activating the
            // app. A first responder in a non-key window shows no caret and receives no keys, so ask
            // for the keyboard first: opening the composer IS the user asking to type
            // (report 2026-09-14_12-13-25).
            if !window.isKeyWindow { window.makeKey() }
            window.makeFirstResponder(field)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: QuickAddTaskField
        var didTakeFocus = false
        init(_ parent: QuickAddTaskField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onCommit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            case #selector(NSResponder.insertTab(_:)):
                // Accepting the project name is ALL Tab does here — it never commits, so a line that is
                // still only a `#token` can't be filed as a task with an empty title. With nothing to
                // accept it returns false and AppKit moves the focus as it always did; swallowing Tab
                // unconditionally would be the worse bug (report 2026-09-15_12-24-31).
                return parent.onAcceptProjectSuggestion()
            case #selector(NSResponder.moveDown(_:)):
                return parent.onMoveProjectSuggestion(1)
            case #selector(NSResponder.moveUp(_:)):
                return parent.onMoveProjectSuggestion(-1)
            default:
                return false
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
    @SwiftUI.State private var blockingOffExpanded = false
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
        model.beginVoiceInput()
        mode = model.inVoiceMode ? .voice : .menu
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
            } else if !model.blockingOffReasons.isEmpty {
                // Only when the onboarding banner isn't already up — it covers the same ground for a
                // user who has never set blocking up, and two cards saying it would be shouting.
                blockingOffCard
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

            if model.classSessionJoinable {
                classSessionCard
            }

            AccordionRow(icon: "cup.and.saucer.fill",
                         title: menuLocalized("menuBreaks", "Breaks"),
                         subtitle: model.breaksSummary.isEmpty ? menuLocalized("menuTakeBreak", "Take a mindful break") : model.breaksSummary,
                         solid: highlightedSection == .breaks,
                         identifier: UITestContract.Identifier.SettingsRegression.menuBreaksRow,
                         isOpen: binding(.breaks), scheme: scheme) {
                VStack(alignment: .leading, spacing: 8) {
                    if !model.lastBreakText.isEmpty {
                        Text(model.lastBreakText)
                            .font(MenuTheme.font(12, .regular))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                    }
                    if model.canStartBreak {
                        LinkButton(title: menuLocalized("menuStartBreak", "Start a break now"), scheme: scheme,
                                   identifier: UITestContract.Identifier.SettingsRegression.menuStartBreakLink, action: model.onOpenBreaks)
                    }
                }
            }

            AccordionRow(icon: "calendar",
                         title: menuLocalized("menuDayPlan", "Day Plan"),
                         subtitle: dayPlanSubtitle,
                         solid: highlightedSection == .dayPlan,
                         identifier: UITestContract.Identifier.SettingsRegression.menuDayPlanRow,
                         isOpen: binding(.dayPlan), scheme: scheme) {
                dayPlanBody
            }

            AccordionRow(icon: "ellipsis",
                         title: menuLocalized("menuFocusTools", "Focus Tools"),
                         // When a focus-music track is loaded, surface it (and a pause control) at the
                         // top level so it's identifiable/pausable without opening the accordion.
                         subtitle: model.musicTrackName.isEmpty
                            ? menuLocalized("menuFocusToolsSubtitleNotes", "Music, notes & to-dos")
                            : "♪ " + model.musicTrackName,
                         solid: highlightedSection == .tools,
                         accessory: model.musicTrackName.isEmpty ? nil : AnyView(
                            MusicToggleButton(playing: model.musicPlaying, scheme: scheme, action: model.onToggleMusic)
                         ),
                         identifier: UITestContract.Identifier.SettingsRegression.menuToolsRow,
                         isOpen: binding(.tools), scheme: scheme) {
                VStack(spacing: 8) {
                    if model.musicTrackName.isEmpty {
                        ToolButton(icon: "music.note", title: menuLocalized("menuFocusMusic", "Focus Music"), scheme: scheme,
                                   identifier: UITestContract.Identifier.SettingsRegression.menuFocusMusicButton, action: model.onOpenFocusMusic)
                    } else {
                        // A track is loaded: play/pause icon on the left + the track name.
                        ToolButton(icon: model.musicPlaying ? "pause.fill" : "play.fill",
                                   title: model.musicTrackName, scheme: scheme, action: model.onToggleMusic)
                    }
                    ToolButton(icon: "note.text", title: menuLocalized("menuNotes", "Notes"), scheme: scheme,
                               identifier: UITestContract.Identifier.SettingsRegression.menuNotesButton, action: model.onOpenBrainDump)
                    ToolButton(icon: "checklist", title: menuLocalized("menuToDoPlayer", "To-Do Player"), scheme: scheme,
                               identifier: UITestContract.Identifier.SettingsRegression.menuToDoPlayerButton, action: model.onOpenToDoPlayer)
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
        // Measure at the REAL popover width, not maxWidth:.infinity — otherwise the GeometryReader below
        // measures during an unbounded-width pass where wrapping subtitles collapse to one line, under-
        // reporting the height, so the popover/window is sized too short and clips (top icons + bottom row).
        .frame(width: FocusBearMenuView.width, alignment: .leading)
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
                IconButton(systemName: "mic", scheme: scheme, identifier: UITestContract.Identifier.SettingsRegression.menuMicButton, action: startVoice)
                    .help(HotkeyService.voiceInputShortcutDisplay)
            }
            IconButton(systemName: model.menuPinnedAsWindow ? "pin.fill" : "pin", scheme: scheme,
                       identifier: UITestContract.Identifier.SettingsRegression.menuPinButton, action: model.onTogglePin)
            // Expand, not a cog: the popover is a summary of the day, so the natural thing to reach for
            // from its header is the full Day Plan (report 2026-09-15_17-46-04). Preferences is still a
            // click away once the main window is open — the Day Plan opens it, and its left menu has
            // Settings. Same action as the "View full day plan" link below.
            // Mirrored so the arrows run bottom-left to top-right, which is the direction the PO asked
            // for. The symbol that draws that diagonal natively (arrow.down.left.and.arrow.up.right) is
            // macOS 14+, and on macOS 11-13 a missing symbol draws nothing at all, so the icon would
            // simply vanish for those users.
            IconButton(systemName: "arrow.up.left.and.arrow.down.right", scheme: scheme,
                       help: menuLocalized("menuViewFullDayPlan", "View full day plan"),
                       mirroredHorizontally: true,
                       identifier: UITestContract.Identifier.MenuBar.openDayPlanButton,
                       action: model.onOpenDayPlan)
            IconButton(systemName: "power", scheme: scheme, identifier: UITestContract.Identifier.MenuBar.quitButton,
                       action: model.onQuit)
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
                            .accessibilityIdentifier(UITestContract.Identifier.SettingsRegression.menuFocusGoalField)
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
                                    // #777: switching mode in the expanded list re-defaults the duration to
                                    // the newly-selected mode's last-used value (same handler as expand).
                                    .onChange(of: model.selectedBlockListId) { _ in model.onFocusStarterExpanded() }
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
                SwiftUI.Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded = nil; model.focusStarterExpanded = true; model.onFocusStarterExpanded() } }) {
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
                .accessibilityIdentifier(UITestContract.Identifier.SettingsRegression.menuStartFocusButton)
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

    /// Blocking health card: the headline distinguishes inactive blocking from limited capabilities,
    /// clicking it reveals WHY — every reason that currently applies, each with the button that
    /// fixes it (permissions wizard, blocking-schedule settings, resume, reactivate). #1978
    private var blockingOffCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SwiftUI.Button(action: { blockingOffExpanded.toggle() }) {
                HStack(spacing: 10) {
                    Image(systemName: BlockingStatusCardKind(reasons: model.blockingOffReasons) == .off ? "shield.slash" : "exclamationmark.shield")
                        .font(.system(size: 18))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                    Text(BlockingStatusCardKind(reasons: model.blockingOffReasons).title)
                        .font(MenuTheme.font(14, .semibold))
                        .foregroundColor(MenuTheme.primaryText(scheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 8)
                    Text(menuLocalized("blockingOffWhy", "Why?"))
                        .font(MenuTheme.font(12, .semibold))
                        .foregroundColor(MenuTheme.orange)
                    Image(systemName: blockingOffExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MenuTheme.orange)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

            if blockingOffExpanded {
                ForEach(model.blockingOffReasons, id: \.self) { reason in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reason == .permissionsMissing && !model.blockingPermissionIssues.isEmpty
                             ? model.blockingPermissionIssues.map(\.explanation).joined(separator: "\n\n")
                             : reason.explanation)
                            .font(MenuTheme.font(12, .regular))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        LinkButton(title: reason.fixTitle, scheme: scheme) { model.onFixBlockingOff(reason) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(MenuTheme.cardBg(scheme))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(MenuTheme.border(scheme), lineWidth: 1))
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

    // "A class focus session is running" + a "Join session" button, for a student who declined/dismissed
    // the join prompt while the session is still live (#2267). Styled like blockingScheduleCard.
    private var classSessionCard: some View {
        HStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 18))
                    .foregroundColor(MenuTheme.orange)
                // Title wraps to as many lines as it needs (no truncation) so it's fully visible even
                // when the Join button narrows the column; the session name sits below in a smaller font.
                VStack(alignment: .leading, spacing: 3) {
                    Text(classSessionRunningTitleText)
                        .font(MenuTheme.font(14, .semibold))
                        .foregroundColor(MenuTheme.primaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                    if !model.classSessionName.isEmpty {
                        Text(model.classSessionName)
                            .font(MenuTheme.font(11, .regular))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
            }

            SwiftUI.Button(action: model.onJoinClassSession) {
                Text(classSessionJoinButtonText)
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

    // Card title + button read from the teacherSessionInfo config block (same block the join prompt uses),
    // so they localize consistently and fall back to English if the block/key isn't present.
    private var classSessionRunningTitleText: String {
        if let info = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary,
           let s = info.value(forKey: "classSessionRunningTitle") as? String, !s.isEmpty {
            return s
        }
        return "A class focus session is running"
    }

    private var classSessionJoinButtonText: String {
        if let info = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary,
           let s = info.value(forKey: "buttonJoin") as? String, !s.isEmpty {
            return s
        }
        return "Join session"
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
                     // Always "Focus:" with the running focus mode/name to the right (never the goal).
                     title: focusAccordionTitle,
                     subtitle: focusSubtitle,
                     solid: highlightedSection == .focus,
                     identifier: UITestContract.Identifier.MenuBar.focusSection,
                     isOpen: binding(.focus), scheme: scheme) {
            VStack(alignment: .leading, spacing: 8) {
                intentionEditor
                currentTaskRow
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

    /// The task the session is playing, with a tick to finish it here and a link out to the focus
    /// screen to pick a different one ("show the current task playing in the focus UI with an option
    /// for me to mark it as complete… also a 'Change task' link", report 2026-09-15_16-43-04).
    /// Completing routes through `FocusSessionQueueWriter`, the same path the focus screen uses, so
    /// the Day Plan and the to-do list follow along.
    @ViewBuilder private var currentTaskRow: some View {
        HStack(alignment: .center, spacing: 6) {
            if model.focusCurrentTaskTitle.isEmpty {
                Text(menuLocalized("menuNoCurrentTask", "No task chosen"))
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.subtitle(scheme))
            } else {
                if model.focusTaskActionable {
                    SwiftUI.Button(action: model.onCompleteCurrentTask) {
                        // The same tick-off affordance the day-plan rows below use.
                        Image(systemName: "circle")
                            .font(.system(size: 15))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .help(menuLocalized("menuMarkTaskComplete", "Mark as complete"))
                }
                Text(model.focusCurrentTaskTitle)
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.primaryText(scheme))
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            SwiftUI.Button(action: model.onChangeTask) {
                Text(menuLocalized("menuChangeTask", "Change task"))
                    .font(MenuTheme.font(12, .medium))
                    .foregroundColor(MenuTheme.orange)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .help(menuLocalized("menuOpenFocusScreen", "Open the full focus screen"))
        }
    }

    /// The focus-session intention: tap it (dotted underline signals it's editable) to type a new one,
    /// confirm with the tick. Saving routes through onSaveIntention → updateFocusModeIntention.
    @ViewBuilder private var intentionEditor: some View {
        if !model.focusGoalEditable {
            // Super-strict mode: the goal is locked. Show it read-only (no pencil / no tap); the reason
            // ("can't change in super-strict") is a tooltip on the lock icon.
            HStack(alignment: .center, spacing: 6) {
                Text(menuFocusGoalLabel())
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.subtitle(scheme))
                if !model.focusTaskTitle.isEmpty {
                    Text(model.focusTaskTitle)
                        .font(MenuTheme.font(13, .medium))
                        .foregroundColor(MenuTheme.primaryText(scheme))
                        .lineLimit(2)
                        // Two lines is not always enough — hover for the whole goal.
                        .instantTooltip(model.focusTaskTitle)
                }
                Spacer(minLength: 0)
                // AppKit-backed so the tooltip shows the instant the pointer enters (SwiftUI `.help` is slow).
                InstantTooltipIcon(symbol: "lock.fill", message: menuCannotChangeGoalNote())
                    .frame(width: 18, height: 18)
            }
        } else if editingIntention {
            HStack(spacing: 6) {
                Text(menuFocusGoalLabel())
                    .font(MenuTheme.font(13, .medium))
                    .foregroundColor(MenuTheme.subtitle(scheme))
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
        } else {
            // Always show the "Focus Goal:" label; the goal value (editable, dashed underline) sits to its
            // right, or nothing when no goal is set.
            SwiftUI.Button(action: { intentionDraft = model.focusTaskTitle; editingIntention = true }) {
                HStack(alignment: .center, spacing: 6) {
                    Text(menuFocusGoalLabel())
                        .font(MenuTheme.font(13, .medium))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                    if !model.focusTaskTitle.isEmpty {
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
                            // The overlay never takes a click, so the row still opens for editing.
                            .instantTooltip(model.focusTaskTitle)
                    }
                    Spacer(minLength: 6)
                    // Pencil (kept right-aligned) so the row reads as editable even when no goal is set.
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MenuTheme.orange.opacity(0.85))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .help(menuLocalized("menuEditIntention", "Edit intention"))
        }
    }

    private func saveIntention() {
        // Never change the goal in super-strict mode (defensive — the edit UI isn't reachable there).
        guard model.focusGoalEditable else { editingIntention = false; return }
        // Save whatever was entered, including an empty string — clearing the goal is a valid edit
        // (onSaveIntention → updateFocusModeIntention clears whatToAchieveInFocusBlock + the label).
        let trimmed = intentionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        model.onSaveIntention(trimmed)
        // Reflect the new goal in the model immediately; otherwise the view shows the old value until the
        // next ~1s tick re-reads it from the legacy label.
        model.focusTaskTitle = trimmed
        editingIntention = false
    }

    private var focusSubtitle: String {
        model.focusRemaining.isEmpty
            ? menuLocalized("menuSessionRunning", "Session running")
            : "\(model.focusRemaining) " + menuLocalized("menuRemaining", "remaining")
    }

    /// Always the static "Focus:" label, with the running focus mode/name to its right when available.
    private var focusAccordionTitle: String {
        let label = menuLocalized("menuFocus", "Focus") + ":"
        return model.focusModeName.isEmpty ? label : label + " " + model.focusModeName
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
        // A habit is in progress → the header shows the CURRENT habit (the NEXT HABIT line below shows the
        // following one), so the two rows never duplicate.
        if !model.dayPlanCurrentHabit.isEmpty { return model.dayPlanCurrentHabit }
        // Nothing startable right now → surface the next routine's start time here (the first-habit
        // preview goes in the NEXT HABIT line below).
        if !model.dayPlanRoutineStart.isEmpty { return model.dayPlanRoutineStart }
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

            // "+ Add task" — always offered (also when the list is empty, so the first task of the
            // day can be typed here) and always directly above "View full day plan".
            quickAddSection

            if model.dayPlanNextEventTitle.isEmpty && model.dayPlanNextHabit.isEmpty && model.dayPlanTasks.isEmpty {
                Text(menuLocalized("menuNothingScheduled", "Nothing scheduled right now"))
                    .font(MenuTheme.font(12, .regular))
                    .foregroundColor(MenuTheme.subtitle(scheme))
            }
            LinkButton(title: menuLocalized("menuViewFullDayPlan", "View full day plan"), scheme: scheme,
                       identifier: UITestContract.Identifier.SettingsRegression.menuViewFullDayPlanLink, action: model.onOpenDayPlan)
        }
    }

    // MARK: Inline quick-add task

    /// What the typed line currently means. Recomputed per keystroke (the parser is pure and cheap)
    /// so the chips below the field always describe what would actually be added.
    private var quickAddParsed: ParsedQuickAddTask {
        QuickAddTaskParser.parse(model.quickAddText, knownProjects: model.quickAddProjectNames)
    }

    /// Whether the typed line is addable, decided by the same rule the Day Plan composer commits by,
    /// so a line that is nothing but tokens is refused identically on both.
    private var quickAddCommit: TaskNameCommit {
        TaskNameCommit.forQuickAdd(model.quickAddText, knownProjects: model.quickAddProjectNames)
    }

    private var quickAddIsAddable: Bool {
        if case .save = quickAddCommit { return true }
        return false
    }

    private var quickAddSection: some View {
        Group {
            if model.quickAddExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MenuTheme.orange)
                        QuickAddTaskField(text: $model.quickAddText,
                                          placeholder: menuLocalized("menuAddTaskPlaceholder",
                                                                     "Task name #project 30m"),
                                          onCommit: commitQuickAdd,
                                          onCancel: collapseQuickAdd,
                                          onAcceptProjectSuggestion: acceptHighlightedProjectSuggestion,
                                          onMoveProjectSuggestion: moveProjectSuggestionHighlight)
                            .frame(height: 18)
                        SwiftUI.Button(action: commitQuickAdd) {
                            Image(systemName: "return")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(quickAddIsAddable ? MenuTheme.orange : MenuTheme.subtitle(scheme))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                        .disabled(!quickAddIsAddable)
                        .help(menuLocalized("menuAddTask", "Add task"))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(MenuTheme.orange.opacity(0.10)))
                    // The same ⌘V handler the task editors use. Here the picture cannot be uploaded
                    // yet — there is no task — so it is held and sent the moment one exists.
                    .attachesPastedImages(label: "menu-quick-add") { model.quickAddPastedImage = $0 }
                    quickAddProjectSuggestions
                    quickAddPreview
                    quickAddShortcutCard
                }
            } else {
                SwiftUI.Button(action: { model.quickAddExpanded = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 15))
                            .foregroundColor(MenuTheme.orange)
                        Text(menuLocalized("menuAddTask", "Add task"))
                            .font(MenuTheme.font(13, .medium))
                            .foregroundColor(MenuTheme.orange)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
            }
        }
    }

    /// Known project names matching the `#token` being typed. Without these the composer took any text
    /// after `#` and a typo minted a new project (report 2026-09-14_16-17-22). Clicking one accepts it;
    /// the field keeps the keyboard, so typing can continue straight away. The highlighted row — the one
    /// Tab accepts — is tinted, so "the highlighted suggestion" means something on screen.
    @ViewBuilder
    private var quickAddProjectSuggestions: some View {
        let matches = quickAddProjectMatches
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element) { index, name in
                    SwiftUI.Button(action: { acceptProjectSuggestion(at: index) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder").font(.system(size: 10))
                            Text(name).font(MenuTheme.font(11, .regular)).lineLimit(1)   // i18n-ignore: the user's own project name
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(index == model.quickAddSuggestionIndex ? MenuTheme.orange.opacity(0.18) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
            .foregroundColor(MenuTheme.orange)
            .background(RoundedRectangle(cornerRadius: 6).fill(MenuTheme.chipBg(scheme)))
        }
    }

    /// The project names offered for the `#token` being typed — the single list the highlight, the
    /// clickable rows and Tab all read, so they can never disagree about what "the first match" is.
    private var quickAddProjectMatches: [String] {
        QuickAddProjectSuggestions.matches(for: model.quickAddText, knownProjects: model.quickAddProjectNames)
    }

    /// The one way a `#project` suggestion is accepted: a click passes the row it was on, Tab passes the
    /// highlighted row. Both land here, so the two can't drift apart — and neither commits the task, so
    /// the empty-title guard still has the last word on Enter.
    @discardableResult
    private func acceptProjectSuggestion(at index: Int) -> Bool {
        guard let accepted = QuickAddProjectSuggestions.accepting(model.quickAddText,
                                                                 knownProjects: model.quickAddProjectNames,
                                                                 suggestion: index)
        else { return false }
        model.quickAddText = accepted
        return true
    }

    /// Tab accepts the highlighted suggestion (report 2026-09-15_12-24-31). It reports whether it had
    /// anything to do: with no suggestion showing, Tab falls through to normal focus movement.
    private func acceptHighlightedProjectSuggestion() -> Bool {
        acceptProjectSuggestion(at: model.quickAddSuggestionIndex)
    }

    private func moveProjectSuggestionHighlight(by delta: Int) -> Bool {
        let matches = quickAddProjectMatches
        guard matches.count > 1 else { return false }
        let moved = max(0, min(matches.count - 1, model.quickAddSuggestionIndex + delta))
        guard moved != model.quickAddSuggestionIndex else { return true }
        model.quickAddSuggestionIndex = moved
        return true
    }

    /// The same shortcut explainer the Day Plan row shows, in the menu's own idiom. Dismissing either
    /// one dismisses both: what the ✕ retires is the explanation, not one surface of it. The list is
    /// the MENU grammar, which has one token more than the row's — a spelled "30m" counts here.
    @ViewBuilder
    private var quickAddShortcutCard: some View {
        if model.showsQuickAddShortcutCard {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 6) {
                    Text(TaskShortcutCard.title)
                        .font(MenuTheme.font(10, .semibold))
                        .foregroundColor(MenuTheme.primaryText(scheme))
                    Spacer(minLength: 0)
                    SwiftUI.Button(action: model.dismissQuickAddShortcutCard) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(MenuTheme.subtitle(scheme))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .help(TaskShortcutCard.dismissTooltip)
                }
                ForEach(TaskShortcutCard.hints(for: .menuQuickAdd), id: \.self) { hint in
                    Text(hint)
                        .font(MenuTheme.font(10, .regular))
                        .foregroundColor(MenuTheme.subtitle(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(MenuTheme.chipBg(scheme)))
        }
    }

    /// Chips echoing back what the typed tokens were understood as; falls back to the key hint so the
    /// row always explains itself.
    private var quickAddPreview: some View {
        HStack(spacing: 6) {
            if let project = quickAddParsed.project, !project.isEmpty {
                quickAddChip(text: "#\(project)", icon: "folder")   // i18n-ignore: the user's own project name
            }
            if let minutes = quickAddParsed.durationMinutes {
                quickAddChip(text: QuickAddTaskParser.durationLabel(minutes), icon: "clock")
            }
            if let outcome = quickAddParsed.outcome {
                quickAddChip(text: "\(outcome)", icon: "star")
            }
            // A pasted image is invisible otherwise, and a silent ⌘V is worse than no ⌘V at all.
            if model.quickAddPastedImage != nil {
                quickAddChip(text: menuLocalized("menuQuickAddImagePending", "Image attached"),
                             icon: "paperclip")
            }
            // Tokens but no name: Enter is disabled, so say why rather than leaving it dead.
            if case .refuseTokensOnly = quickAddCommit {
                Text(ScheduleText.tasksNameNeeded)
                    .font(MenuTheme.font(10, .regular))
                    .foregroundColor(MenuTheme.orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else if quickAddParsed.project == nil && quickAddParsed.durationMinutes == nil && quickAddParsed.outcome == nil {
                Text(menuLocalized("menuAddTaskHint", "Enter to add, Esc to cancel"))
                    .font(MenuTheme.font(10, .regular))
                    .foregroundColor(MenuTheme.subtitle(scheme))
            }
            Spacer(minLength: 0)
        }
    }

    private func quickAddChip(text: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(MenuTheme.font(10, .medium)).lineLimit(1)
        }
        .foregroundColor(MenuTheme.orange)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Capsule().fill(MenuTheme.chipBg(scheme)))
    }

    /// Enter: add the task to TODAY's Day Plan and clear the field, leaving it open and focused so a
    /// run of tasks can be typed without re-opening the menu.
    private func commitQuickAdd() {
        guard quickAddIsAddable else { return }
        let raw = model.quickAddText
        let pasted = model.quickAddPastedImage
        model.quickAddText = ""
        model.quickAddPastedImage = nil
        model.onQuickAddTask(raw, pasted)
    }

    private func collapseQuickAdd() {
        model.quickAddText = ""
        model.quickAddPastedImage = nil
        model.quickAddExpanded = false
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
        // Measure at the REAL popover width, not maxWidth:.infinity — otherwise the GeometryReader below
        // measures during an unbounded-width pass where wrapping subtitles collapse to one line, under-
        // reporting the height, so the popover/window is sized too short and clips (top icons + bottom row).
        .frame(width: FocusBearMenuView.width, alignment: .leading)
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
            IconButton(systemName: model.menuPinnedAsWindow ? "pin.fill" : "pin", scheme: scheme,
                       identifier: UITestContract.Identifier.SettingsRegression.menuPinButton, action: model.onTogglePin)
            IconButton(systemName: "gearshape", scheme: scheme,
                       identifier: UITestContract.Identifier.MenuBar.preferencesButton, action: model.onPreferences)
            IconButton(systemName: "power", scheme: scheme, identifier: UITestContract.Identifier.MenuBar.quitButton,
                       action: model.onQuit)
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
    /// For UI tests to find the row's header by.
    var identifier: String = ""
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
            .accessibilityIdentifier(identifier)

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
    /// For UI tests to find it by.
    var identifier: String = ""
    let action: () -> Void
    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(MenuTheme.font(12, .semibold))
                .foregroundColor(MenuTheme.orange)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .accessibilityIdentifier(identifier)
    }
}

@available(macOS 11.0, *)
private struct ToolButton: View {
    let icon: String
    let title: String
    let scheme: ColorScheme
    /// For UI tests to find it by.
    var identifier: String = ""
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
        .accessibilityIdentifier(identifier)
    }
}

@available(macOS 11.0, *)
private struct IconButton: View {
    let systemName: String
    let scheme: ColorScheme
    /// Tooltip + accessibility label. Optional because the long-standing icons (mic, pin, power) read
    /// unambiguously on their own; icons whose meaning isn't obvious should always pass one.
    var help: String? = nil
    /// Flips the glyph left-to-right (the glyph only — the circular background is symmetric). The one
    /// user is the expand arrow, whose bottom-left-to-top-right diagonal only exists as its own SF
    /// Symbol from macOS 14 and this app still runs on macOS 11; mirroring the macOS 10.15 symbol
    /// gives that exact glyph on every version, from one code path.
    var mirroredHorizontally: Bool = false
    /// For UI tests to find it by.
    var identifier: String = ""
    let action: () -> Void

    @ViewBuilder var body: some View {
        let button = SwiftUI.Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MenuTheme.primaryText(scheme).opacity(0.7))
                .scaleEffect(x: mirroredHorizontally ? -1 : 1, y: 1)
                .frame(width: 30, height: 30)
                .background(MenuTheme.iconButtonBg(scheme))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .accessibilityIdentifier(identifier)
        if let help = help {
            button.help(help).accessibilityLabel(Text(help))
        } else {
            button
        }
    }
}

// MARK: - Off-screen snapshot (dev self-check, no popover needed)

@available(macOS 13.0, *)
@MainActor
enum MenuSnapshot {
    static func renderIfRequested() {
        guard OffscreenRenderLaunch.isMenuSnapshot else { return }
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
        m.focusCurrentTaskTitle = "Write the release notes"
        m.focusTaskActionable = true
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
        case .brainDump:  return menuLocalized("menuNotes", "Notes")
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
