//
//  AiBlockBuddyView.swift
//  Focus Bear
//
//  The SwiftUI screen for the AI-block accountability buddy (the check-in shown when the AI relevance
//  check decides the current app/site doesn't match the current task), styled to the Figma design
//  "AI Blocking Latest" (Sid Focus Bear Design, section 5415:95407). Pure presentation: every action is
//  a callback wired by `AiBlockBuddyHostingController` in `AiBlockBuddyScreen.swift`, which also owns
//  the window, dismissal and block/allow primitives.
//
//  Design states (three Figma frames of the same screen):
//    • plain (5278:82671)   — white background, the three top tasks as a row of cards.
//    • stacked (5392:93360) — the top-task cards as full-width rows when their titles don't fit three
//                             across (the design shows the same tasks untruncated in this variant).
//    • blurred (5395:93532) — shown over the blocked app: the app bleeds through blurred under a
//                             white gradient, and the cards/row pick up a soft shadow.
//

import Cocoa
import SwiftUI

// MARK: - Strings (single registry, config-driven)

/// User-facing copy for the AI block buddy screen, kept in one place. Read from the `aiBlockBuddyInfo`
/// block of config.json (so it can be translated) with English defaults: at runtime `configjson` is the
/// DOWNLOADED remote config, which only carries these keys once the assets change ships, so without the
/// defaults the whole check-in would render blank. Same "default then override" pattern as
/// `AccountabilityBuddyStrings`.
enum AiBlockBuddyText {
    private static let configBlockKey = "aiBlockBuddyInfo"
    /// Substitution marker inside templated strings (the item name / minute count).
    private static let templatePlaceholder = "{0}"

    /// English defaults (a plain dictionary, not UI-sink literals, so the hardcoded-strings check
    /// doesn't flag them). Config values override these for translation.
    private static let englishDefaults: [String: String] = [
        "couldWaitTitle": "This looks like it could wait...",
        "lowerPriority": "Hey — it looks like you might be working on something lower priority ({0}).",
        "topTasksIntro": "Here's a reminder of the top tasks in your day plan:",
        "noTasks": "You don't have any tasks in your Day Plan yet. Add a couple so your buddy can help you prioritise.",
        "pickHint": "Pick a task to switch to it",
        "markTaskComplete": "mark complete",

        // Current-task alignment + the current-task picker dropdown
        "alignToCurrentTaskPrefix": "{0} doesn't seem to align with your current task",
        // …and the other possibility: the current TASK is what doesn't fit the session.
        "taskOffIntentionTitle": "Hmm, is this the right task?",
        "taskOffIntentionPrefix": "Your current task doesn't seem to match what you set out to do this session: {0}",
        "taskOffIntentionHint": "That's why things are getting blocked — not {0} itself. Switch to a task that fits, or update your current task.",
        "currentTaskBadge": "CURRENT TASK",
        "changeCurrentTaskHint": "Change your current task",
        "updateTaskPlaceholder": "Type to pick or add a task",
        "switchToAnotherTask": "Switch to another task",
        "taskChangedTo": "Task changed to {0}",

        // Report-bad-AI + the on-hover decision detail
        "reportBadAiTooltip": "Report a bad AI decision",
        "reportBadAiPrompt": "What did it get wrong?",
        "reportBadAiPlaceholder": "This is relevant because…",
        "reportBadAiSend": "Send report",
        "reportBadAiDone": "Thanks — reported for review",
        "aiReasonPrefix": "AI reason:",
        "alignmentScorePrefix": "Focus alignment:",
        "aiDecisionNoDetail": "No AI reason recorded for this decision.",
        "aiDecisionDetailHint": "Why your buddy flagged this",

        "argueButton": "This is relevant - let me explain",
        "blockButton": "Block it and stay focused",
        "saveCurrentButton": "Save as task for later",
        "back": "Back",

        // Save-task step
        "saveCurrentTitle": "Save what you're doing as a task",
        "saveCurrentSubtitle": "We'll add this to your Day Plan so you can come back to it later.",
        "fieldTitle": "Title",
        "titleGeneratingPlaceholder": "Generating a title…",
        "fieldDescription": "Description",
        "fieldDuration": "Duration (min)",
        "fieldProject": "Project",
        "projectPlaceholder": "Type to search or add a project",
        "saveTaskButton": "Save task",

        // Argue-with-AI step
        "argueHeader": "Could you tell me why it's relevant?",
        "argueThinking": "Checking against your top task…",
        "argueInputPlaceholder": "Why does this help your top task?",
        "argueSend": "Send",
        "argueDurationPrompt": "How long do you need?",
        "argueMinutesUnit": "min",
        "argueAllowForButton": "Let me use it for {0} min",
        "argueError": "Something went wrong. You can try again, or block it and stay focused.",

        // Offline fallback — the AI buddy needs the network (every verdict is a backend call), so when the
        // computer is offline we replace the chat with a deliberate hold-to-unlock gate.
        "offlineTitle": "You're offline",
        "offlineBody": "Your buddy needs an internet connection to check whether this is relevant right now. Hold the button to unlock it anyway, or stay focused.",
        "offlineHoldButton": "Hold to unlock",
    ]

    private static func text(_ key: String) -> String {
        let info = configjson.value(forKey: configBlockKey) as? NSDictionary
        let fromConfig = (info?.value(forKey: key) as? String) ?? ""
        return fromConfig.isEmpty ? (englishDefaults[key] ?? "") : fromConfig
    }

    /// The big heading of the check-in: "This looks like it could wait..."
    static var couldWaitTitle: String { text("couldWaitTitle") }
    /// "Hey — it looks like you might be working on something lower priority (<item>)."
    static func lowerPriority(_ item: String) -> String {
        text("lowerPriority").replacingOccurrences(of: templatePlaceholder, with: item)
    }
    static var topTasksIntro: String { text("topTasksIntro") }
    static var noTasks: String { text("noTasks") }
    static var pickHint: String { text("pickHint") }
    static var markTaskComplete: String { text("markTaskComplete") }

    /// "<item> doesn't seem to align with your current task:"
    static func alignToCurrentTask(_ item: String) -> String {
        text("alignToCurrentTaskPrefix").replacingOccurrences(of: templatePlaceholder, with: item)
    }
    /// Heading shown INSTEAD of `couldWaitTitle` when it's the current task, not the caught item, that
    /// doesn't fit the session — "this looks like it could wait" is about the wrong thing there.
    static var taskOffIntentionTitle: String { text("taskOffIntentionTitle") }
    /// Our own wording for a task/intention mismatch, used only when the server gave no sentence of its
    /// own. `{0}` is the session's focus intention.
    static func taskOffIntention(_ intention: String) -> String {
        text("taskOffIntentionPrefix").replacingOccurrences(of: templatePlaceholder, with: intention)
    }
    /// The line under it that says what to do — and, crucially, that arguing about `{0}` (the caught
    /// app/site) is not the way out.
    static func taskOffIntentionHint(_ item: String) -> String {
        text("taskOffIntentionHint").replacingOccurrences(of: templatePlaceholder, with: item)
    }
    static var currentTaskBadge: String { text("currentTaskBadge") }
    static var changeCurrentTaskHint: String { text("changeCurrentTaskHint") }
    static var updateTaskPlaceholder: String { text("updateTaskPlaceholder") }
    /// Compact link shown instead of the top-3 cards when the user already has a current task —
    /// tapping it reveals the cards on demand.
    static var switchToAnotherTask: String { text("switchToAnotherTask") }
    /// "Task changed to <title>" — the whole screen for a beat after the user changes their task.
    static func taskChangedTo(_ title: String) -> String {
        AiBlockBuddyTaskChange.message(template: text("taskChangedTo"),
                                       placeholder: templatePlaceholder,
                                       title: title)
    }

    static var reportBadAiTooltip: String { text("reportBadAiTooltip") }
    static var reportBadAiPrompt: String { text("reportBadAiPrompt") }
    static var reportBadAiPlaceholder: String { text("reportBadAiPlaceholder") }
    static var reportBadAiSend: String { text("reportBadAiSend") }
    static var reportBadAiDone: String { text("reportBadAiDone") }
    static var aiReasonPrefix: String { text("aiReasonPrefix") }
    static var alignmentScorePrefix: String { text("alignmentScorePrefix") }
    static var aiDecisionNoDetail: String { text("aiDecisionNoDetail") }
    /// Label for the info icon that reveals the AI reason + alignment score.
    static var aiDecisionDetailHint: String { text("aiDecisionDetailHint") }

    static var argueButton: String { text("argueButton") }
    static var blockButton: String { text("blockButton") }
    static var saveCurrentButton: String { text("saveCurrentButton") }
    static var back: String { text("back") }

    static var saveCurrentTitle: String { text("saveCurrentTitle") }
    static var saveCurrentSubtitle: String { text("saveCurrentSubtitle") }
    static var fieldTitle: String { text("fieldTitle") }
    static var titleGeneratingPlaceholder: String { text("titleGeneratingPlaceholder") }
    static var fieldDescription: String { text("fieldDescription") }
    static var fieldDuration: String { text("fieldDuration") }
    static var fieldProject: String { text("fieldProject") }
    static var projectPlaceholder: String { text("projectPlaceholder") }
    static var saveTaskButton: String { text("saveTaskButton") }

    static var argueHeader: String { text("argueHeader") }
    static var argueThinking: String { text("argueThinking") }
    static var argueInputPlaceholder: String { text("argueInputPlaceholder") }
    static var argueSend: String { text("argueSend") }
    static var argueDurationPrompt: String { text("argueDurationPrompt") }
    static var argueMinutesUnit: String { text("argueMinutesUnit") }
    /// "Let me use it for <minutes> min"
    static func argueAllowForButton(_ minutes: Int) -> String {
        text("argueAllowForButton").replacingOccurrences(of: templatePlaceholder, with: String(minutes))
    }
    static var argueError: String { text("argueError") }

    static var offlineTitle: String { text("offlineTitle") }
    static var offlineBody: String { text("offlineBody") }
    static var offlineHoldButton: String { text("offlineHoldButton") }
}

// MARK: - Window size

/// Fixed width and the DESIRED height of the buddy window. The actual height is clamped to the visible
/// screen (see `aiBlockBuddyHeight`) so the window — and its pinned action buttons — never runs off the
/// bottom on short screens. Sized so the Figma layout (an 802pt content column at 1×) reads well at
/// ~0.74× without the type getting too small to read.
let kAiBlockBuddyWidth: CGFloat = 640
let kAiBlockBuddyDesiredHeight: CGFloat = 760
let kAiBlockBuddyMinHeight: CGFloat = 480

// MARK: - Design tokens

/// Every size on the screen, derived from the Figma frames ("AI Blocking Latest": 3456px-wide 2× frames
/// whose content column is 802pt at 1×). `pt(_:)` scales a 1× design value to the buddy window's content
/// width so the proportions match the design at the real window size. Kept in one place so the screen
/// has no free-floating magic numbers.
enum AiBlockBuddyDesign {
    /// Width of the design's content column at 1× (the 1605px column of the 2× frame).
    private static let designContentWidth: CGFloat = 802
    static let outerPadding: CGFloat = 24
    static let contentWidth: CGFloat = kAiBlockBuddyWidth - 2 * outerPadding
    static let scale: CGFloat = contentWidth / designContentWidth

    /// A 1× design value scaled to the window, rounded to half points so strokes stay crisp.
    static func pt(_ design: CGFloat) -> CGFloat { (design * scale * 2).rounded() / 2 }

    // Type (design 1× sizes)
    static let introSize = pt(18)
    static let headingSize = pt(48)
    static let sublineSize = pt(18)
    static let cardTitleSize = pt(16)
    static let stackedCardTitleSize = pt(19)
    static let chipSize = pt(12)
    static let stackedChipSize = pt(13)
    static let currentTaskTitleSize = pt(20)
    static let badgeSize = pt(12)
    static let separatorSize = pt(18)
    static let projectSize = pt(18)
    static let buttonSize = pt(20)
    static let tertiarySize = pt(17)
    static let fieldLabelSize = pt(15)
    static let fieldSize = pt(17)
    static let chatSize = pt(17)
    static let sectionTitleSize = pt(30)

    // Top-task cards
    static let cardGap = pt(8)
    static let stackedCardGap = pt(4)
    static let cardRadius = pt(10)
    static let cardPadding = EdgeInsets(top: pt(12), leading: pt(18), bottom: pt(12), trailing: pt(12))
    static let cardInnerGap = pt(4)
    static let cardControlGap = pt(8)
    static let cardBorderWidth = pt(2)
    static let cardDoneToggleSize = pt(24)
    /// The play (switch-to-task) glyph beside the check button, matched to its size.
    static let cardPlayIconSize = cardDoneToggleSize
    static let chipPadding = EdgeInsets(top: pt(4), leading: pt(8), bottom: pt(4), trailing: pt(8))
    static let chipRadius = pt(8)
    /// Line height the app's fonts lay out at, for the height estimates that size the bear.
    static let lineHeightFactor: CGFloat = 1.2
    static let chipHeight = chipPadding.top + chipPadding.bottom + chipSize * lineHeightFactor
    static let stackedChipHeight = chipPadding.top + chipPadding.bottom + stackedChipSize * lineHeightFactor
    /// Card heights: the row card stacks title over chip; the stacked card puts them side by side.
    static let rowCardHeight = cardPadding.top + cardPadding.bottom + cardTitleSize * lineHeightFactor + cardInnerGap + chipHeight
    static let stackedCardHeight = cardPadding.top + cardPadding.bottom
        + max(stackedCardTitleSize * lineHeightFactor, stackedChipHeight, cardDoneToggleSize)

    // Vertical rhythm
    static let introToCardsGap = pt(18)
    static let cardsToBearGap = pt(40)
    static let bearToHeadingGap = pt(24)
    static let headingToSublineGap = pt(16)
    static let sublineToRowGap = pt(16)
    static let rowToActionsGap = pt(40)
    static let actionsGap = pt(8)
    static let bearMaxHeight = pt(327)
    static let bearMinHeight = pt(100)
    /// Bear image aspect (the Figma group is 393.5 × 327 at 1×).
    static let bearAspect: CGFloat = 393.5 / 327

    // Current-task row
    static let rowHeight = pt(48.5)
    static let rowHorizontalPadding = pt(20)
    static let rowRadius = pt(16.8)
    static let rowBorderWidth = pt(2)
    static let rowItemGap = pt(6)
    static let rowToCheckGap = pt(12)
    static let badgePadding = EdgeInsets(top: pt(5.5), leading: pt(7), bottom: pt(5.5), trailing: pt(6))
    static let badgeRadius = pt(8)
    static let chevronSize = pt(20)
    static let checkButtonSize = pt(48)
    static let checkButtonRadius = pt(12)
    static let checkIconSize = pt(20)

    // AI-decision detail panel (revealed by the info icon next to the subline)
    static let infoIconSize = pt(17)
    static let detailPanelGap = pt(10)
    static let detailPanelPadding = pt(12)
    static let detailLineGap = pt(4)
    static let detailTextSize = pt(15)

    // Current-task picker dropdown (opens under the row)
    static let pickerGap = pt(6)
    static let pickerMaxListHeight = pt(220)
    static let pickerRowPadding = EdgeInsets(top: pt(9), leading: pt(14), bottom: pt(9), trailing: pt(14))

    // Buttons
    static let buttonHeight = pt(78)
    static let buttonRadius = pt(10)
    static let compactButtonHeight = pt(48)
    static let tertiaryButtonHeight = pt(40)

    // Shadow the blurred variant adds to cards / the task row (Figma: 0 0 40px rgba(0,0,0,0.1) at 2×).
    static let cardShadowRadius = pt(20)
    static let cardShadowOpacity = 0.1

    // Fields (save / argue steps)
    static let fieldRadius = pt(10)
    static let fieldPadding = pt(10)
    static let fieldGap = pt(14)
    static let bubbleRadius = pt(14)
    static let bubblePadding = EdgeInsets(top: pt(9), leading: pt(13), bottom: pt(9), trailing: pt(13))
}

/// Colours from the Figma frames, with dark-appearance counterparts (the design is light-only). The
/// brand orange is the design's #DE7400, not the app's older `dark_OrangeColor`.
enum AiBlockBuddyPalette {
    static let accent = Color(red: 0xDE / 255, green: 0x74 / 255, blue: 0x00 / 255)
    /// "CURRENT TASK" badge gradient (#F9AE0E → #DE7400).
    static let currentTaskGradient = Gradient(colors: [
        Color(red: 0xF9 / 255, green: 0xAE / 255, blue: 0x0E / 255), accent,
    ])
    /// Chip fill behind an uppercase orange project tag (#FFEBD3).
    static let accentTint = dynamic(light: NSColor(red: 1, green: 0xEB / 255, blue: 0xD3 / 255, alpha: 1),
                                    dark: NSColor(red: 0xDE / 255, green: 0x74 / 255, blue: 0, alpha: 0.22))
    /// Card / row hairline (#E4E4E7).
    static let border = dynamic(light: NSColor(red: 0xE4 / 255, green: 0xE4 / 255, blue: 0xE7 / 255, alpha: 1),
                                dark: NSColor.white.withAlphaComponent(0.14))
    static let cardFill = dynamic(light: .white, dark: NSColor.white.withAlphaComponent(0.08))
    /// Opaque surface for the task-picker dropdown (it floats over the buttons, so it can't be translucent).
    static let popoverFill = dynamic(light: .white, dark: NSColor(white: 0.17, alpha: 1))
    /// The current-task row fill (#FAFAFA).
    static let rowFill = dynamic(light: NSColor(white: 0xFA / 255, alpha: 1),
                                 dark: NSColor.white.withAlphaComponent(0.06))
    /// Secondary button / check-button hairline (rgba(113,113,122,0.2)).
    static let neutralFill = Color(red: 113 / 255, green: 113 / 255, blue: 122 / 255).opacity(0.2)
    /// The faint warm hairline both big buttons carry (rgba(255,249,242,0.4)).
    static let buttonHairline = Color(red: 1, green: 0xF9 / 255, blue: 0xF2 / 255).opacity(0.4)
    /// Hairline the badges carry (rgba(255,255,255,0.2)).
    static let badgeHairline = Color.white.opacity(0.2)
    static let ink = Color(NSColor.labelColor)
    static let inkMuted = Color(NSColor.labelColor).opacity(0.5)
    static let background = Color(NSColor.windowBackgroundColor)
    static let chatUserBubble = accent
    static let chatBuddyBubble = neutralFill

    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

/// Return / keypad-Enter key codes, for the typeahead's own Return guard.
private let kAiBlockBuddyReturnKeyCode: UInt16 = 36
private let kAiBlockBuddyKeypadEnterKeyCode: UInt16 = 76

/// The asset-catalog name of the Figma bear illustration (fly-swatter bear on its grey ground).
private let kAiBlockBuddyBearImageName = "aiBuddyBear"

// The app's font helpers respect the user's chosen font (e.g. OpenDyslexic); `Font(NSFont)` bridges them.
private func buddyRegular(_ size: CGFloat) -> Font { Font(getRegularFont(size: size)) }
private func buddyMedium(_ size: CGFloat) -> Font { Font(getMediumFont(size: size)) }
private func buddySemibold(_ size: CGFloat) -> Font { Font(getSemiBoldFont(size: size)) }

// MARK: - Backdrop (plain vs blurred-over-the-app)

/// How the screen sits over what's behind it: on a plain opaque window, or (the design's blurred
/// variant) letting the blocked app bleed through blurred under a white gradient. `blendingMode` is
/// `.behindWindow` in the app (the blur backdrop window sits behind the buddy); `.withinWindow` lets an
/// offscreen render harness composite over an image inside one window.
enum AiBlockBuddyBackdrop: Equatable {
    case plain
    case blurred(blendingMode: NSVisualEffectView.BlendingMode)

    static let blurredBehindWindow = AiBlockBuddyBackdrop.blurred(blendingMode: .behindWindow)
    var isBlurred: Bool { self != .plain }
}

/// `NSVisualEffectView` bridge so the blocked app behind the window shows through frosted.
private struct AiBlockBuddyBlurView: NSViewRepresentable {
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sheet
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.blendingMode = blendingMode
    }
}

/// The screen background for a given backdrop: solid window colour, or the blur under the design's
/// horizontal white gradient (0.82 → 1 → 0.8 opacity) so the middle stays fully readable.
private struct AiBlockBuddyBackground: View {
    let backdrop: AiBlockBuddyBackdrop

    var body: some View {
        switch backdrop {
        case .plain:
            AiBlockBuddyPalette.background
        case .blurred(let blendingMode):
            ZStack {
                AiBlockBuddyBlurView(blendingMode: blendingMode)
                LinearGradient(
                    gradient: Gradient(colors: [
                        AiBlockBuddyPalette.background.opacity(0.82),
                        AiBlockBuddyPalette.background,
                        AiBlockBuddyPalette.background.opacity(0.8),
                    ]),
                    startPoint: .leading, endPoint: .trailing)
            }
        }
    }
}

/// Card-style container chrome: fill, hairline border, radius — plus the soft shadow only the blurred
/// variant adds (a shadow on plain white is invisible in the design).
private struct AiBlockBuddyCardChrome: ViewModifier {
    let fill: Color
    let radius: CGFloat
    let borderWidth: CGFloat
    let backdrop: AiBlockBuddyBackdrop

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(AiBlockBuddyPalette.border, lineWidth: borderWidth))
            .shadow(color: Color.black.opacity(backdrop.isBlurred ? AiBlockBuddyDesign.cardShadowOpacity : 0),
                    radius: AiBlockBuddyDesign.cardShadowRadius)
    }
}

private extension View {
    func buddyCard(fill: Color, radius: CGFloat, borderWidth: CGFloat, backdrop: AiBlockBuddyBackdrop) -> some View {
        modifier(AiBlockBuddyCardChrome(fill: fill, radius: radius, borderWidth: borderWidth, backdrop: backdrop))
    }
}

// MARK: - Button styles

/// The design's two big full-width buttons: filled orange with white text (primary) and the neutral
/// grey fill with dark text (secondary). Both carry the faint warm hairline and the same radius.
struct AiBlockBuddyButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    let kind: Kind
    var height: CGFloat = AiBlockBuddyDesign.buttonHeight
    var fontSize: CGFloat = AiBlockBuddyDesign.buttonSize

    func makeBody(configuration: Configuration) -> some View {
        let fill: Color = kind == .primary ? AiBlockBuddyPalette.accent : AiBlockBuddyPalette.neutralFill
        let text: Color = kind == .primary ? .white : AiBlockBuddyPalette.ink
        return configuration.label
            .font(buddyMedium(fontSize))
            .foregroundColor(text)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.buttonRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.buttonRadius, style: .continuous)
                        .stroke(AiBlockBuddyPalette.buttonHairline, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Rectangle())
            .pointingHandCursor()
    }
}

/// A quiet text-only action under the big buttons (the report-bad-AI link, the offline "block it").
struct AiBlockBuddyTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(buddyMedium(AiBlockBuddyDesign.tertiarySize))
            .foregroundColor(AiBlockBuddyPalette.inkMuted)
            .frame(maxWidth: .infinity, minHeight: AiBlockBuddyDesign.tertiaryButtonHeight)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Rectangle())
            .pointingHandCursor()
    }
}

/// The square bordered check button beside the current-task row (Figma "Button with Icon").
private struct AiBlockBuddyCheckButton: View {
    let isDone: Bool
    let size: CGFloat
    let backdrop: AiBlockBuddyBackdrop
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(isDone ? .white : AiBlockBuddyPalette.ink)
                .frame(width: size, height: size)
                .background(isDone ? AiBlockBuddyPalette.accent : AiBlockBuddyPalette.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                            .stroke(isDone ? AiBlockBuddyPalette.accent : AiBlockBuddyPalette.neutralFill,
                                    lineWidth: AiBlockBuddyDesign.rowBorderWidth))
                .shadow(color: Color.black.opacity(backdrop.isBlurred ? AiBlockBuddyDesign.cardShadowOpacity : 0),
                        radius: AiBlockBuddyDesign.cardShadowRadius)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .help(AiBlockBuddyText.markTaskComplete)
    }
}

/// The project tag on a task card. Matches the native To-do list's chip (`ToDoChip`): a "#project"
/// label in the accent colour on a soft accent fill — no leading glyph. (The Figma chip carried a heart;
/// it read as a mistake next to a project name, so it's dropped.)
private struct AiBlockBuddyProjectChip: View {
    let project: String
    let textSize: CGFloat

    var body: some View {
        Text("#" + project)
            .font(buddyMedium(textSize))
            .lineLimit(1)
            .foregroundColor(AiBlockBuddyPalette.accent)
            .padding(AiBlockBuddyDesign.chipPadding)
            .background(AiBlockBuddyPalette.accentTint)
            .clipShape(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.chipRadius, style: .continuous))
    }
}

/// A small gradient badge ("CURRENT TASK") on the task row.
private struct AiBlockBuddyBadge: View {
    let text: String
    let gradient: Gradient

    var body: some View {
        Text(text)
            .font(buddySemibold(AiBlockBuddyDesign.badgeSize))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(AiBlockBuddyDesign.badgePadding)
            .background(LinearGradient(gradient: gradient, startPoint: .topTrailing, endPoint: .bottomLeading))
            .clipShape(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.badgeRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.badgeRadius, style: .continuous)
                        .stroke(AiBlockBuddyPalette.badgeHairline, lineWidth: 1))
    }
}

/// The "⋄" between items on the task row.
private struct AiBlockBuddyRowSeparator: View {
    var body: some View {
        Text("⋄")
            .font(buddyMedium(AiBlockBuddyDesign.separatorSize))
            .foregroundColor(AiBlockBuddyPalette.inkMuted)
    }
}

/// Header of the save / argue steps: a Back link and the step's title in the design's type.
private struct AiBlockBuddyStepHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AiBlockBuddyDesign.headingToSublineGap) {
            SwiftUI.Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: AiBlockBuddyDesign.fieldLabelSize, weight: .semibold))
                    Text(AiBlockBuddyText.back).font(buddyMedium(AiBlockBuddyDesign.fieldSize))
                }
                .foregroundColor(AiBlockBuddyPalette.inkMuted)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            Text(title)
                .font(buddySemibold(AiBlockBuddyDesign.sectionTitleSize))
                .foregroundColor(AiBlockBuddyPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Bordered field chrome shared by the save form's inputs and the argue input, in the row's styling.
private struct AiBlockBuddyFieldChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AiBlockBuddyDesign.fieldPadding)
            .background(AiBlockBuddyPalette.rowFill)
            .clipShape(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.fieldRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.fieldRadius, style: .continuous)
                        .stroke(AiBlockBuddyPalette.border, lineWidth: 1))
    }
}

private extension View {
    func buddyField() -> some View { modifier(AiBlockBuddyFieldChrome()) }
}

// MARK: - Typed-task resolution

/// What a name typed into the current-task picker means: the CANONICAL title of an existing Day Plan
/// task when the text matches one (ignoring case and surrounding whitespace) — so picking "payroll"
/// adopts the existing "Payroll" instead of creating a near-duplicate — else the trimmed text itself,
/// which the caller creates as a brand-new task. nil when nothing was typed.
func aiBlockBuddyResolveTypedTaskTitle(_ typed: String, existingTitles: [String]) -> String? {
    let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return existingTitles.first { $0.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(trimmed) == .orderedSame }
        ?? trimmed
}

/// How changing the current task is acknowledged before the check-in closes.
///
/// Picking a task (or typing one and pressing Return) used to dismiss the whole window on the same
/// runloop turn, so the only feedback that anything had happened was the screen disappearing
/// (report 2026-09-17_13-54-19). The change is now confirmed on its own — "Task changed to <title>",
/// nothing else on screen — and committed once the confirmation has been up for
/// `confirmationSeconds`. Kept as plain values so the rules are testable without a view.
enum AiBlockBuddyTaskChange {
    /// How long the confirmation holds the screen before the change is committed and the check-in
    /// closes. Long enough to read the task name, short enough not to feel like a wait.
    static let confirmationSeconds: TimeInterval = 0.5

    /// The title a typed or picked name commits as, or nil when there is nothing to change to — a
    /// blank name must neither be confirmed nor committed.
    static func committedTitle(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Fills the localised "Task changed to {0}" template with the task's title.
    static func message(template: String, placeholder: String, title: String) -> String {
        template.replacingOccurrences(of: placeholder, with: title)
    }
}

/// The task to offer as the new current task once one is completed: the highest-ranked still-open task
/// in the order the check-in already ranks its top-task cards (`topTitles`, from
/// `incompleteTasksInDisplayOrder`), falling back to the rest of today's open tasks in the same order.
/// `excluding` holds the titles already ticked off in this check-in — the one just completed included —
/// so the buddy never offers back the task the user just finished. nil when nothing is left to suggest.
func aiBlockBuddyNextTaskSuggestion(topTitles: [String], otherTitles: [String], excluding excluded: [String]) -> String? {
    func key(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    let excludedKeys = Set(excluded.map(key))
    var seen = Set<String>()
    for title in topTitles + otherTitles {
        let candidate = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty, !excludedKeys.contains(key(candidate)), seen.insert(key(candidate)).inserted else { continue }
        return candidate
    }
    return nil
}

// MARK: - Current-task picker dropdown

/// Where the current-task row sits inside the choose phase, so the dropdown can hang off it.
private struct AiBlockBuddyRowFrameKey: PreferenceKey {
    static let coordinateSpace = "aiBlockBuddyChoose"
    static var defaultValue: CGRect = .zero
    /// Only the row reports a frame; every sibling contributes the default, which must not clobber it.
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// The dropdown under the current-task row: a typeahead on top, then — when the typed text isn't already
/// one of them — a row for the typed task with an explicit play control (Return alone wasn't a visible
/// affordance), then the matching Day Plan tasks. Clicking a row, its play control, or pressing Return
/// picks the task; Escape closes.
private struct AiBlockBuddyTaskPicker: View {
    @SwiftUI.Binding var query: String
    let taskTitles: [String]
    let maxListHeight: CGFloat
    let onPick: (String) -> Void
    let onCancel: () -> Void

    /// The typed text as a task, shown as its own row — nil when nothing is typed or when it simply names
    /// a task already in the list below (no point offering the same task twice).
    private var typedTask: String? {
        guard let resolved = aiBlockBuddyResolveTypedTaskTitle(query, existingTitles: taskTitles) else { return nil }
        return matches.contains(resolved) ? nil : resolved
    }

    /// Return on typed text: adopt the matching Day Plan task, or create one under the typed name.
    /// Blank input does nothing (the dropdown stays open).
    private func commitTypedTask() {
        guard let title = aiBlockBuddyResolveTypedTaskTitle(query, existingTitles: taskTitles) else { return }
        onPick(title)
    }

    /// One row of the dropdown: the task's title, and — for the typed-task row — the play control that
    /// makes "start this task" clickable rather than leaving Return as the only way in.
    private func pickerRow(_ title: String, showsPlayControl: Bool) -> some View {
        SwiftUI.Button(action: { onPick(title) }) {
            HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
                Text(title)
                    .font(buddyRegular(AiBlockBuddyDesign.fieldSize))
                    .foregroundColor(AiBlockBuddyPalette.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if showsPlayControl {
                    Image(systemName: "play.fill")
                        .font(.system(size: AiBlockBuddyDesign.cardPlayIconSize * 0.5, weight: .semibold))
                        .foregroundColor(AiBlockBuddyPalette.accent)
                        .frame(width: AiBlockBuddyDesign.cardPlayIconSize, height: AiBlockBuddyDesign.cardPlayIconSize)
                }
            }
            .padding(AiBlockBuddyDesign.pickerRowPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .help(AiBlockBuddyText.pickHint)
    }

    private var matches: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? taskTitles : taskTitles.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        VStack(spacing: 0) {
            AiBlockBuddyTypeaheadField(text: $query, placeholder: AiBlockBuddyText.updateTaskPlaceholder,
                                       onCommit: commitTypedTask, onCancel: onCancel)
                .padding(AiBlockBuddyDesign.pickerRowPadding)
            if let typed = typedTask {
                Divider()
                pickerRow(typed, showsPlayControl: true)
            }
            if !matches.isEmpty {
                Divider()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(matches, id: \.self) { title in
                            pickerRow(title, showsPlayControl: false)
                        }
                    }
                }
                .frame(maxHeight: maxListHeight)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(AiBlockBuddyPalette.popoverFill)
        .clipShape(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.fieldRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.fieldRadius, style: .continuous)
                    .stroke(AiBlockBuddyPalette.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: AiBlockBuddyDesign.cardShadowRadius)
    }
}

/// The picker's typeahead: an `NSTextField` that takes focus as soon as it appears (SwiftUI has no focus
/// control on macOS 11), commits on Return and cancels on Escape.
private struct AiBlockBuddyTypeaheadField: NSViewRepresentable {
    @SwiftUI.Binding var text: String
    let placeholder: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    /// Swallows Return itself. Key equivalents are offered to the view hierarchy BEFORE the field editor
    /// sees the keystroke, so in the app's borderless full-screen window a default button (the routine's
    /// "Start", or any SwiftUI `.keyboardShortcut(.defaultAction)` in this window) consumes Return and the
    /// typed task was silently dropped. Same guard as `EditOnClickTextField` in the Day Plan.
    final class GuardedTextField: NSTextField {
        var onCommit: () -> Void = {}

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if event.type == .keyDown, event.keyCode == kAiBlockBuddyReturnKeyCode || event.keyCode == kAiBlockBuddyKeypadEnterKeyCode,
               let editor = currentEditor(), window?.firstResponder === editor {
                onCommit()
                return true
            }
            return super.performKeyEquivalent(with: event)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> GuardedTextField {
        let field = GuardedTextField()
        field.onCommit = { context.coordinator.parent.onCommit() }
        field.placeholderString = placeholder
        field.font = getRegularFont(size: AiBlockBuddyDesign.fieldSize)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.stringValue = text
        DispatchQueue.main.async { field.window?.makeFirstResponder(field) }
        return field
    }

    func updateNSView(_ field: GuardedTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text { field.stringValue = text }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: AiBlockBuddyTypeaheadField
        init(_ parent: AiBlockBuddyTypeaheadField) { self.parent = parent }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        /// Backstop for when the keystroke does reach the field editor (no default button competing):
        /// Return commits, Escape closes. Both are also handled in `GuardedTextField.performKeyEquivalent`,
        /// which wins when a default button would otherwise eat Return first.
        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) { parent.onCommit(); return true }
            if selector == #selector(NSResponder.cancelOperation(_:)) { parent.onCancel(); return true }
            return false
        }
    }
}

// MARK: - Offline (hold to unlock)

/// Shown in place of `AiBlockBuddyView` when the computer is offline: the AI relevance chat can't run
/// without the network, so the user unlocks the caught app/site by deliberately holding a button for
/// `kAiBlockOfflineHoldSeconds` (reuses `HoldToPostponeButton`), or blocks it and stays focused.
struct AiBlockHoldToUnlockView: View {
    let itemLabel: String
    let contentHeight: CGFloat
    var backdrop: AiBlockBuddyBackdrop = .plain
    let onBlock: () -> Void
    let onHoldComplete: () -> Void

    var body: some View {
        VStack(spacing: AiBlockBuddyDesign.headingToSublineGap) {
            Spacer(minLength: 0)
            Image(kAiBlockBuddyBearImageName)
                .resizable()
                .aspectRatio(AiBlockBuddyDesign.bearAspect, contentMode: .fit)
                .frame(maxHeight: AiBlockBuddyDesign.bearMinHeight * 1.4)
            Image(systemName: "wifi.slash")
                .font(.system(size: AiBlockBuddyDesign.sectionTitleSize))
                .foregroundColor(AiBlockBuddyPalette.inkMuted)
            Text(AiBlockBuddyText.offlineTitle)
                .font(buddySemibold(AiBlockBuddyDesign.headingSize))
                .foregroundColor(AiBlockBuddyPalette.ink)
                .multilineTextAlignment(.center)
            Text(AiBlockBuddyText.lowerPriority(itemLabel))
                .font(buddyRegular(AiBlockBuddyDesign.sublineSize))
                .foregroundColor(AiBlockBuddyPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(AiBlockBuddyText.offlineBody)
                .font(buddyRegular(AiBlockBuddyDesign.sublineSize))
                .foregroundColor(AiBlockBuddyPalette.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HoldToPostponeButton(seconds: kAiBlockOfflineHoldSeconds,
                                 title: AiBlockBuddyText.offlineHoldButton,
                                 accent: AiBlockBuddyPalette.accent,
                                 onComplete: onHoldComplete)
                .frame(height: AiBlockBuddyDesign.compactButtonHeight)
            SwiftUI.Button(AiBlockBuddyText.blockButton, action: onBlock)
                .buttonStyle(AiBlockBuddyTertiaryButtonStyle())
        }
        .padding(AiBlockBuddyDesign.outerPadding)
        .frame(width: kAiBlockBuddyWidth, height: contentHeight)
        .background(AiBlockBuddyBackground(backdrop: backdrop))
    }
}

// MARK: - The screen

struct AiBlockBuddyView: View {
    let itemLabel: String
    /// The user's live focus intention / current task, shown prominently so they can see what the caught
    /// item is being judged against. Empty when no intention is set.
    let currentIntention: String
    /// The session's stated GOAL (`whatToAchieveInFocusBlock`), which is a different thing from the task
    /// above: the task is what the user is doing right now, the goal is what the session is for. Only used
    /// to name the goal when the two turn out to disagree. Empty when the session has no stated goal.
    let sessionIntention: String
    /// The Day Plan task the intention corresponds to (matched by title), when there is one — gives the
    /// row its project label and lets the check button mark it done. nil for a free-text intention.
    let currentTask: DayPlanTask?
    /// True when the user picked/updated a task via the check-in within the last
    /// `kAiBlockBuddyCompactAfterPickSeconds` — i.e. this is the ~15s re-block after a pick, so the top-task
    /// cards start collapsed behind the "Switch to another task" link. Otherwise they show by default.
    let taskPickedRecently: Bool
    let topTasks: [DayPlanTask]
    /// Titles of today's incomplete Day Plan tasks, for the "update your current task" type-to-filter field.
    let existingTaskTitles: [String]
    let projectNames: [String]
    /// Default text for the save-task Description field (the caught URL, blank for an app block).
    let defaultNotes: String
    /// The caught page's tab title, used as the title fallback when the AI guess fails (preferred over
    /// the bare domain). Empty for an app block.
    let pageTitle: String
    /// The screen-clamped height the view must lay out to — matches the hosting view + window so the
    /// pinned controls stay on-screen (see `aiBlockBuddyHeight`).
    let contentHeight: CGFloat
    /// Plain white, or the design's blurred-over-the-app variant (when the blur backdrop is up).
    var backdrop: AiBlockBuddyBackdrop = .plain
    /// Pick or create the active task by name (an existing Day Plan task is adopted, else a new one is
    /// created + adopted); then the buddy dismisses and re-checks the caught item against the new task.
    let onUpdateCurrentTask: (String) -> Void
    /// Switch the active task to the picked top-3 task (then the parent re-checks the current page).
    let onSwitch: (DayPlanTask) -> Void
    /// Mark a task complete, or un-mark it, right from the check-in (same path as the Day Plan's "Done").
    let onSetTaskDone: (DayPlanTask, Bool) -> Void
    /// Save the current activity as a standalone Day Plan task (no top-task switch, no block).
    let onSaveTask: (DayPlanTask) -> Void
    let onEvaluate: (String, [AiBlockChatMessage], @escaping (Result<AiRelevanceVerdict, Error>) -> Void) -> Void
    /// Ask the AI to guess a task title for the caught app/site (async, best-effort; nil ⇒ keep default).
    let onSuggestTitle: (@escaping (String?) -> Void) -> Void
    /// Allow the caught app/site for the given number of minutes (the user's chosen time box), passing the
    /// user's argue-chat justification so it can be recorded for later backend relevance checks.
    let onAllow: (Int, String) -> Void
    /// The AI's stated reason for the block and the site's focus-alignment score (0–100), surfaced on
    /// hover over the current-task row so the user can see WHY it was judged off-task. Either may be nil.
    let aiBlockReason: String?
    let alignmentScore: Double?
    /// Report this block as a bad AI decision (captured for review). Best-effort; fire-and-forget.
    /// Carries the user's own words on what the AI got wrong — a report without them is unreadable
    /// in the review stream (report 2026-09-14_15-05-53).
    let onReportBadAi: (String) -> Void
    /// Ask whether the CURRENT TASK itself serves the session goal, so the screen can blame the right
    /// thing. Deliberately NOT awaited before the first paint: the user is looking at a modal, so the
    /// check-in renders with the ordinary wording straight away and this rewrites it in place if an
    /// answer comes back. Answers `.itemOffTask` — the wording this screen has always used — unless the
    /// session is super strict AND there is a task to compare AND the check came back with a conflict.
    let onCheckTaskAlignment: (@escaping (AiBlockBuddySubtitle) -> Void) -> Void

    /// `taskChanged` is the brief acknowledgement between the user changing their task and the check-in
    /// closing — see `AiBlockBuddyTaskChange`.
    private enum Phase { case choose, save, argue, taskChanged }

    /// How the top-task cards lay out: the design's row of three (`plain` frame) or full-width stacked
    /// rows (`stacked` frame) when a title wouldn't fit in a third of the width.
    private enum TopTasksLayout { case row, stacked }

    /// True once the user has flagged this decision, so the report control confirms + disables.
    @SwiftUI.State private var didReportBadAi = false
    @SwiftUI.State private var isWritingBadAiReason = false
    @SwiftUI.State private var badAiReason = ""

    // The app defines global `State`/`Button` types that shadow SwiftUI's — qualify them.
    @SwiftUI.State private var phase: Phase = .choose

    /// Whether the AI-decision detail panel is PINNED open (the info icon was clicked). A click toggles it;
    /// it stays until clicked again or the check-in closes.
    @SwiftUI.State private var isAiDetailPinned = false
    /// Whether the pointer is over the info icon — reveals the same panel transiently.
    @SwiftUI.State private var isAiDetailHovered = false
    private var isAiDetailVisible: Bool { isAiDetailPinned || isAiDetailHovered }

    /// Whether the current-task picker dropdown is open under the row (the row / its chevron toggles it).
    @SwiftUI.State private var isTaskPickerOpen = false
    /// Text typed into the picker's typeahead — filters the Day Plan tasks, or names a brand-new one.
    @SwiftUI.State private var taskPickerQuery: String = ""
    /// The task the confirmation screen is announcing, while `phase` is `.taskChanged`.
    @SwiftUI.State private var changedTaskTitle = ""
    /// The task the user picked from the dropdown this session, so the row shows it straight away (the
    /// parent adopts it and re-checks; `currentIntention` itself is a fixed snapshot). nil = unchanged.
    @SwiftUI.State private var pickedIntention: String? = nil
    /// Where the current-task row sits in the screen's coordinate space, so the dropdown can hang off it.
    @SwiftUI.State private var currentTaskRowFrame: CGRect = .zero
    private var shownIntention: String { pickedIntention ?? currentIntention }

    /// The server's answer to "is the current task itself off-goal?", once it arrives. Starts at
    /// `.itemOffTask` so the screen paints immediately with the wording it has always used, and is
    /// replaced in place when (and only when) the check comes back with a clear conflict.
    @SwiftUI.State private var taskAlignment: AiBlockBuddySubtitle = .itemOffTask
    /// One check per presentation. `onAppear` can fire again (e.g. the view re-enters the hierarchy);
    /// the answer can't have changed, and the parent's cache would serve it anyway.
    @SwiftUI.State private var didRequestTaskAlignment = false

    /// Which of the two things the subtitle should blame.
    ///
    /// With no task and no goal there is nothing to compare, so the "lower priority" line stands. Once
    /// the user picks a task inside this check-in, any verdict in hand is about the task they just left,
    /// so it is dropped (the pick dismisses and re-checks anyway).
    private var subtitleKind: AiBlockBuddySubtitle {
        if shownIntention.isEmpty { return .noCurrentTask }
        if pickedIntention != nil { return .itemOffTask }
        return taskAlignment
    }

    private var isCurrentTaskOffIntention: Bool {
        if case .currentTaskOffIntention = subtitleKind { return true }
        return false
    }

    /// Whether the top-task cards are shown. When the user JUST picked a task via the check-in
    /// (`taskPickedRecently` — the ~15s re-block after a pick) they start collapsed behind a compact
    /// "Switch to another task" link so the re-shown check-in isn't the full picker again; tapping the link
    /// reveals them. `nil` means the user hasn't overridden the default, which is: show the cards UNLESS a
    /// task was just picked. Once the user taps the link this is pinned to `true`.
    @SwiftUI.State private var showTaskPickers: Bool? = nil
    private var taskPickersVisible: Bool { showTaskPickers ?? !taskPickedRecently }

    /// Ids of tasks the user ticked complete from the check-in this session, so their row strikes through
    /// (they're persisted via `onSetTaskDone`, but `topTasks` / `currentTask` are fixed snapshots).
    /// Un-ticking removes the id again — a mis-click must be reversible.
    @SwiftUI.State private var completedTaskIds: Set<String> = []

    // Save-side-quest form
    @SwiftUI.State private var sideQuestTitle: String = ""
    @SwiftUI.State private var sideQuestDuration: String = "15"
    @SwiftUI.State private var sideQuestProject: String = ""   // "" = no project
    @SwiftUI.State private var sideQuestNotes: String = ""
    /// The last value we PREFILLED into the title field. Lets the async AI guess replace the title only
    /// while the user hasn't typed their own — never clobbering an edit.
    @SwiftUI.State private var prefilledTitle: String = ""
    /// True while the AI title guess is in flight — the Title field shows a spinner + placeholder and
    /// stays empty (never the bare domain) until the guess (or its fallback) arrives.
    @SwiftUI.State private var isGuessingTitle = false

    var body: some View {
        Group {
            switch phase {
            case .choose:      chooseView
            case .save:        saveView
            case .argue:       argueView
            case .taskChanged: taskChangedView
            }
        }
        .frame(width: kAiBlockBuddyWidth, height: contentHeight)
        .background(AiBlockBuddyBackground(backdrop: backdrop))
    }

    /// Report a wrong block for review — a quiet text link under the two big buttons. Tapping it asks
    /// WHY first: "it got this wrong" without the reason tells a reviewer nothing, and the legacy
    /// report screen has always collected one. Confirms + disables once sent. (The AI's reason +
    /// alignment score live in the info-icon panel, not a tooltip here.)
    private var reportBadAiLink: some View {
        VStack(alignment: .leading, spacing: 6) {
            SwiftUI.Button(badAiLinkTitle, action: beginReportingBadAi)
                .buttonStyle(AiBlockBuddyTertiaryButtonStyle())
                .disabled(didReportBadAi)
            if isWritingBadAiReason, !didReportBadAi {
                HStack(spacing: 8) {
                    TextField(AiBlockBuddyText.reportBadAiPlaceholder, text: $badAiReason,
                              onCommit: sendBadAiReport)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SwiftUI.Button(AiBlockBuddyText.reportBadAiSend, action: sendBadAiReport)
                        .buttonStyle(AiBlockBuddyTertiaryButtonStyle())
                        .disabled(trimmedBadAiReason.isEmpty)
                }
            }
        }
    }

    private var trimmedBadAiReason: String {
        badAiReason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var badAiLinkTitle: String {
        if didReportBadAi { return AiBlockBuddyText.reportBadAiDone }
        return isWritingBadAiReason ? AiBlockBuddyText.reportBadAiPrompt : AiBlockBuddyText.reportBadAiTooltip
    }

    private func beginReportingBadAi() {
        guard !didReportBadAi else { return }
        isWritingBadAiReason = true
    }

    private func sendBadAiReport() {
        guard !didReportBadAi, !trimmedBadAiReason.isEmpty else { return }
        didReportBadAi = true
        isWritingBadAiReason = false
        onReportBadAi(trimmedBadAiReason)
    }

    /// The AI's block reason + the site's focus-alignment score, one line each, for the detail panel the
    /// info icon reveals. Omits whichever piece is unavailable; falls back to the "no detail" line.
    private var aiDecisionDetailLines: [String] {
        var parts: [String] = []
        if let reason = aiBlockReason?.trimmingCharacters(in: .whitespacesAndNewlines), !reason.isEmpty {
            parts.append(AiBlockBuddyText.aiReasonPrefix + " " + reason)
        }
        if let score = alignmentScore {
            parts.append(AiBlockBuddyText.alignmentScorePrefix + " \(Int(score.rounded()))%")
        }
        return parts.isEmpty ? [AiBlockBuddyText.aiDecisionNoDetail] : parts
    }

    // MARK: Choose (top tasks, bear, heading, current task, actions)

    private var chooseView: some View {
        // The reminder cards, bear and heading SCROLL; the action buttons are pinned below so they stay
        // on-screen even on short screens / long task titles.
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    topTasksSection
                    Spacer().frame(height: AiBlockBuddyDesign.cardsToBearGap)
                    Image(kAiBlockBuddyBearImageName)
                        .resizable()
                        .aspectRatio(AiBlockBuddyDesign.bearAspect, contentMode: .fit)
                        .frame(height: bearHeight)
                    Spacer().frame(height: AiBlockBuddyDesign.bearToHeadingGap)
                    Text(headingText)
                        .font(buddySemibold(AiBlockBuddyDesign.headingSize))
                        .foregroundColor(AiBlockBuddyPalette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer().frame(height: AiBlockBuddyDesign.headingToSublineGap)
                    sublineWithInfoIcon
                    if isCurrentTaskOffIntention {
                        Spacer().frame(height: AiBlockBuddyDesign.detailPanelGap)
                        taskOffIntentionHint
                    }
                    if isAiDetailVisible {
                        Spacer().frame(height: AiBlockBuddyDesign.detailPanelGap)
                        aiDecisionDetailPanel
                    }
                    Spacer().frame(height: AiBlockBuddyDesign.sublineToRowGap)
                    currentTaskRow
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
                .padding(.top, AiBlockBuddyDesign.outerPadding)
                .padding(.bottom, AiBlockBuddyDesign.rowToActionsGap)
            }
            actionButtons
                .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
                .padding(.bottom, AiBlockBuddyDesign.outerPadding)
        }
        .coordinateSpace(name: AiBlockBuddyRowFrameKey.coordinateSpace)
        .onPreferenceChange(AiBlockBuddyRowFrameKey.self) { currentTaskRowFrame = $0 }
        .overlay(taskPickerOverlay, alignment: .topLeading)
        .onAppear(perform: requestTaskAlignment)
    }

    /// Kick off the "is the current task itself off-goal?" check once the screen is up — never before it,
    /// so no network call is ever between the user and a rendered check-in.
    private func requestTaskAlignment() {
        guard !didRequestTaskAlignment else { return }
        didRequestTaskAlignment = true
        onCheckTaskAlignment { taskAlignment = $0 }
    }

    /// The bear fills whatever height is left once the fixed parts (cards, heading, row, buttons) are
    /// laid out, between the design's full size and a floor that keeps it recognisable on short screens.
    private var bearHeight: CGFloat {
        let lines = AiBlockBuddyDesign.lineHeightFactor
        let cardsHeight: CGFloat = topTasksLayout == .row
            ? AiBlockBuddyDesign.rowCardHeight
            : CGFloat(max(topTasks.count, 1)) * AiBlockBuddyDesign.stackedCardHeight
                + CGFloat(max(topTasks.count - 1, 0)) * AiBlockBuddyDesign.stackedCardGap
        let fixed = AiBlockBuddyDesign.outerPadding * 2
            + AiBlockBuddyDesign.introSize * lines + AiBlockBuddyDesign.introToCardsGap + cardsHeight
            + AiBlockBuddyDesign.cardsToBearGap + AiBlockBuddyDesign.bearToHeadingGap
            + AiBlockBuddyDesign.headingSize * lines + AiBlockBuddyDesign.headingToSublineGap
            + AiBlockBuddyDesign.sublineSize * lines + AiBlockBuddyDesign.sublineToRowGap + AiBlockBuddyDesign.rowHeight
            + AiBlockBuddyDesign.rowToActionsGap + actionButtonsHeight
            // The detail panel deliberately does NOT feed into this: making the bear's frame depend on it
            // meant every hover/click of the info icon re-scaled the (large) bear image, which read as lag.
            // The panel is one or two lines, so it either fits the slack or the surrounding ScrollView takes it.
            // The task/intention hint is left out for the same reason and a sharper one: it appears when an
            // async check lands, so folding it in would re-scale the bear a second or two after the screen
            // settled — the worst possible moment for the layout to twitch.
        return min(AiBlockBuddyDesign.bearMaxHeight, max(AiBlockBuddyDesign.bearMinHeight, contentHeight - fixed))
    }

    private var actionButtonsHeight: CGFloat {
        AiBlockBuddyDesign.buttonHeight * 2 + AiBlockBuddyDesign.actionsGap * 2 + AiBlockBuddyDesign.tertiaryButtonHeight
    }

    /// Argue (primary) / save for later (secondary) as the design's two big buttons, with the quiet
    /// report-bad-AI link under them. There's deliberately no "block it" button: leaving the app/tab (or
    /// the window going away) dismisses the check-in, and Return triggers nothing.
    private var actionButtons: some View {
        VStack(spacing: AiBlockBuddyDesign.actionsGap) {
            SwiftUI.Button(AiBlockBuddyText.argueButton, action: beginArgue)
                .buttonStyle(AiBlockBuddyButtonStyle(kind: .primary))
            SwiftUI.Button(AiBlockBuddyText.saveCurrentButton, action: beginSaveCurrent)
                .buttonStyle(AiBlockBuddyButtonStyle(kind: .secondary))
            reportBadAiLink
        }
    }

    // MARK: Top tasks

    /// The intro line + the top-task cards (or the empty-plan hint), collapsed behind the "Switch to
    /// another task" link right after the user picked a task via the check-in.
    @ViewBuilder private var topTasksSection: some View {
        if !taskPickersVisible {
            switchTaskLink
        } else if topTasks.isEmpty {
            Text(AiBlockBuddyText.noTasks)
                .font(buddyRegular(AiBlockBuddyDesign.introSize))
                .foregroundColor(AiBlockBuddyPalette.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(AiBlockBuddyText.topTasksIntro)
                .font(buddyRegular(AiBlockBuddyDesign.introSize))
                .foregroundColor(AiBlockBuddyPalette.ink)
                .multilineTextAlignment(.center)
            Spacer().frame(height: AiBlockBuddyDesign.introToCardsGap)
            topTaskCards
        }
    }

    /// Compact stand-in for the cards, shown when the user just picked a task. Tapping it reveals them.
    private var switchTaskLink: some View {
        SwiftUI.Button(action: { showTaskPickers = true }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                Text(AiBlockBuddyText.switchToAnotherTask)
            }
            .font(buddyMedium(AiBlockBuddyDesign.introSize))
            .foregroundColor(AiBlockBuddyPalette.accent)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    @ViewBuilder private var topTaskCards: some View {
        switch topTasksLayout {
        case .row:
            HStack(alignment: .top, spacing: AiBlockBuddyDesign.cardGap) {
                ForEach(topTasks, id: \.id) { task in
                    topTaskCard(task, titleSize: AiBlockBuddyDesign.cardTitleSize,
                                chipSize: AiBlockBuddyDesign.chipSize, stacked: false)
                }
            }
        case .stacked:
            VStack(spacing: AiBlockBuddyDesign.stackedCardGap) {
                ForEach(topTasks, id: \.id) { task in
                    topTaskCard(task, titleSize: AiBlockBuddyDesign.stackedCardTitleSize,
                                chipSize: AiBlockBuddyDesign.stackedChipSize, stacked: true)
                }
            }
        }
    }

    /// Row of cards (the design's plain frame, where one of the three titles is allowed to truncate) as
    /// long as at most one title overflows its card; otherwise the stacked full-width rows (its stacked
    /// frame), where every title gets the room it needs.
    private var topTasksLayout: TopTasksLayout {
        guard topTasks.count >= 2 else { return .stacked }
        let cardWidth = (AiBlockBuddyDesign.contentWidth - AiBlockBuddyDesign.cardGap * CGFloat(topTasks.count - 1))
            / CGFloat(topTasks.count)
        let controlsWidth = AiBlockBuddyDesign.cardDoneToggleSize + AiBlockBuddyDesign.cardPlayIconSize
            + AiBlockBuddyDesign.cardControlGap * 2
        let titleRoom = cardWidth - AiBlockBuddyDesign.cardPadding.leading - AiBlockBuddyDesign.cardPadding.trailing
            - controlsWidth
        let font = getSemiBoldFont(size: AiBlockBuddyDesign.cardTitleSize)
        let overflowing = topTasks.filter { task in
            (task.title as NSString).size(withAttributes: [.font: font]).width > titleRoom
        }
        return overflowing.count <= 1 ? .row : .stacked
    }

    /// One top-task card: title + project chip; tapping the card switches to the task (the play glyph),
    /// and the separate check control marks it done — a separate button so ticking never triggers the switch.
    private func topTaskCard(_ task: DayPlanTask, titleSize: CGFloat, chipSize: CGFloat, stacked: Bool) -> some View {
        let isDone = completedTaskIds.contains(task.id)
        return HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
            SwiftUI.Button(action: { pick(task) }) {
                HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
                    if stacked {
                        HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
                            topTaskTitle(task, size: titleSize, isDone: isDone)
                            if let project = task.project, !project.isEmpty {
                                AiBlockBuddyProjectChip(project: project, textSize: chipSize)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AiBlockBuddyDesign.cardInnerGap) {
                            topTaskTitle(task, size: titleSize, isDone: isDone)
                            if let project = task.project, !project.isEmpty {
                                AiBlockBuddyProjectChip(project: project, textSize: chipSize)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill")
                        .font(.system(size: AiBlockBuddyDesign.cardPlayIconSize * 0.5, weight: .semibold))
                        .foregroundColor(AiBlockBuddyPalette.accent)
                        .frame(width: AiBlockBuddyDesign.cardPlayIconSize, height: AiBlockBuddyDesign.cardPlayIconSize)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(isDone)
            .help(AiBlockBuddyText.pickHint)

            AiBlockBuddyCheckButton(isDone: isDone, size: AiBlockBuddyDesign.cardDoneToggleSize,
                                    backdrop: .plain) { toggleTaskDone(task) }
        }
        .padding(AiBlockBuddyDesign.cardPadding)
        .frame(maxWidth: .infinity)
        .opacity(isDone ? 0.55 : 1)
        .buddyCard(fill: AiBlockBuddyPalette.cardFill, radius: AiBlockBuddyDesign.cardRadius,
                   borderWidth: AiBlockBuddyDesign.cardBorderWidth, backdrop: backdrop)
    }

    private func topTaskTitle(_ task: DayPlanTask, size: CGFloat, isDone: Bool) -> some View {
        Text(task.title)
            .font(buddySemibold(size))
            .foregroundColor(AiBlockBuddyPalette.ink)
            .strikethrough(isDone, color: AiBlockBuddyPalette.inkMuted)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    /// Toggle a task's done state from the check-in: strike / un-strike it and persist via `onSetTaskDone`
    /// (which mirrors the Day Plan's own completion). Un-ticking exists so an accidental "mark complete"
    /// can be undone without leaving the prompt.
    private func toggleTaskDone(_ task: DayPlanTask) {
        let done = !completedTaskIds.contains(task.id)
        if done { completedTaskIds.insert(task.id) } else { completedTaskIds.remove(task.id) }
        onSetTaskDone(task, done)
    }

    /// "This looks like it could wait…" — unless the CURRENT TASK is what doesn't fit the session, in
    /// which case nothing about the caught item is in question and that heading would point at the
    /// wrong thing entirely.
    private var headingText: String {
        isCurrentTaskOffIntention ? AiBlockBuddyText.taskOffIntentionTitle : AiBlockBuddyText.couldWaitTitle
    }

    /// The one line that says what's wrong. Three possibilities, and they are genuinely different
    /// problems for the user: nothing to judge against, the caught item is off-task, or the task itself
    /// is off-goal. For the last one the server's own sentence is preferred — it is localised and names
    /// both the goal and the task, which our template can only half do.
    private var sublineText: String {
        switch subtitleKind {
        case .noCurrentTask:
            return AiBlockBuddyText.lowerPriority(itemLabel)
        case .itemOffTask:
            return AiBlockBuddyText.alignToCurrentTask(itemLabel)
        case .currentTaskOffIntention(let reason):
            return reason.isEmpty ? AiBlockBuddyText.taskOffIntention(sessionIntention) : reason
        }
    }

    /// Says the quiet part: the block is not about the caught app, so arguing for it can't work — and
    /// points at the two things that can (switch task, or update the current task). Both are reachable
    /// right here, and they are the ONLY things reachable in the session this line can appear in: a
    /// super-strict session locks the focus intention for the duration.
    private var taskOffIntentionHint: some View {
        Text(AiBlockBuddyText.taskOffIntentionHint(itemLabel))
            .font(buddyRegular(AiBlockBuddyDesign.detailTextSize))
            .foregroundColor(AiBlockBuddyPalette.inkMuted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// "<site> doesn't seem to align with your current task" with the info icon that reveals WHY: hovering
    /// shows the detail panel transiently, clicking pins it open until clicked again.
    private var sublineWithInfoIcon: some View {
        HStack(alignment: .firstTextBaseline, spacing: AiBlockBuddyDesign.detailLineGap) {
            Text(sublineText)
                .font(buddyRegular(AiBlockBuddyDesign.sublineSize))
                .foregroundColor(AiBlockBuddyPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            SwiftUI.Button(action: { isAiDetailPinned.toggle() }) {
                Image(systemName: isAiDetailVisible ? "info.circle.fill" : "info.circle")
                    .font(.system(size: AiBlockBuddyDesign.infoIconSize))
                    .foregroundColor(isAiDetailVisible ? AiBlockBuddyPalette.accent : AiBlockBuddyPalette.inkMuted)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .onHover { isAiDetailHovered = $0 }
            .accessibility(label: Text(AiBlockBuddyText.aiDecisionDetailHint))
        }
    }

    /// The AI's reason for the block and the site's focus-alignment score, revealed under the subline —
    /// inside the check-in (pushing the content down), not a floating tooltip.
    private var aiDecisionDetailPanel: some View {
        VStack(alignment: .leading, spacing: AiBlockBuddyDesign.detailLineGap) {
            ForEach(aiDecisionDetailLines, id: \.self) { line in
                Text(line)
                    .font(buddyRegular(AiBlockBuddyDesign.detailTextSize))
                    .foregroundColor(AiBlockBuddyPalette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AiBlockBuddyDesign.detailPanelPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .buddyCard(fill: AiBlockBuddyPalette.rowFill, radius: AiBlockBuddyDesign.cardRadius,
                   borderWidth: 1, backdrop: backdrop)
    }

    // MARK: Current task (the row is the picker)

    /// The row showing what the caught item is being judged against — the user's current task with its
    /// "CURRENT TASK" badge and project — plus the check button that marks it done. (WHY the AI judged this
    /// off-task lives in the info-icon panel above.) The row IS the task picker:
    /// clicking it (or its chevron) opens a dropdown of the Day Plan tasks with a typeahead on top.
    private var currentTaskRow: some View {
        let isDone = currentTask.map { completedTaskIds.contains($0.id) } ?? false
        let hasIntention = !shownIntention.isEmpty
        // The project label belongs to the snapshot task; once the user picks something else it no longer applies.
        let project = pickedIntention == nil ? currentTask?.project : nil
        return HStack(spacing: AiBlockBuddyDesign.rowToCheckGap) {
            SwiftUI.Button(action: toggleTaskPicker) {
                HStack(spacing: AiBlockBuddyDesign.rowItemGap) {
                    Text(hasIntention ? shownIntention : AiBlockBuddyText.updateTaskPlaceholder)
                        .font(buddyRegular(AiBlockBuddyDesign.currentTaskTitleSize))
                        .foregroundColor(hasIntention ? AiBlockBuddyPalette.ink : AiBlockBuddyPalette.inkMuted)
                        .strikethrough(isDone, color: AiBlockBuddyPalette.inkMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                    if hasIntention {
                        AiBlockBuddyRowSeparator()
                        AiBlockBuddyBadge(text: AiBlockBuddyText.currentTaskBadge,
                                          gradient: AiBlockBuddyPalette.currentTaskGradient)
                    }
                    if let project = project, !project.isEmpty {
                        AiBlockBuddyRowSeparator()
                        Text(project)
                            .font(buddyRegular(AiBlockBuddyDesign.projectSize))
                            .foregroundColor(AiBlockBuddyPalette.inkMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: AiBlockBuddyDesign.rowItemGap)
                    Image(systemName: "chevron.down")
                        .font(.system(size: AiBlockBuddyDesign.chevronSize * 0.7, weight: .medium))
                        .foregroundColor(AiBlockBuddyPalette.ink)
                        .rotationEffect(.degrees(isTaskPickerOpen ? 180 : 0))
                        .frame(width: AiBlockBuddyDesign.chevronSize, height: AiBlockBuddyDesign.chevronSize)
                }
                .padding(.horizontal, AiBlockBuddyDesign.rowHorizontalPadding)
                .frame(maxWidth: .infinity, minHeight: AiBlockBuddyDesign.rowHeight, maxHeight: AiBlockBuddyDesign.rowHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .buddyCard(fill: AiBlockBuddyPalette.rowFill, radius: AiBlockBuddyDesign.rowRadius,
                       borderWidth: AiBlockBuddyDesign.rowBorderWidth, backdrop: backdrop)
            .help(AiBlockBuddyText.changeCurrentTaskHint)
            .background(GeometryReader { geo in
                Color.clear.preference(key: AiBlockBuddyRowFrameKey.self,
                                       value: geo.frame(in: .named(AiBlockBuddyRowFrameKey.coordinateSpace)))
            })

            if let task = currentTask, pickedIntention == nil {
                AiBlockBuddyCheckButton(isDone: isDone, size: AiBlockBuddyDesign.checkButtonSize,
                                        backdrop: backdrop) { toggleCurrentTaskDone(task) }
            }
        }
    }

    /// Tick the CURRENT task off. Completing it persists through the same Day Plan path as every other
    /// completion (`onSetTaskDone` → `DayPlanTaskStore.update`, which reflects onto the backing to-do), and
    /// then asks the obvious next question: the picker opens pre-filled with the next-ranked open task, so
    /// one more click starts it. Un-ticking is still just an undo — no prompt.
    private func toggleCurrentTaskDone(_ task: DayPlanTask) {
        let wasDone = completedTaskIds.contains(task.id)
        toggleTaskDone(task)
        guard !wasDone else {
            isTaskPickerOpen = false
            return
        }
        taskPickerQuery = nextTaskSuggestion(afterCompleting: task) ?? ""
        isTaskPickerOpen = true
    }

    /// The task to pre-fill the picker with after `completed` was ticked off: the next-ranked open task,
    /// skipping everything ticked off in this check-in (the just-completed task included).
    private func nextTaskSuggestion(afterCompleting completed: DayPlanTask) -> String? {
        var excluded = topTasks.filter { completedTaskIds.contains($0.id) }.map { $0.title }
        excluded.append(completed.title)
        if !shownIntention.isEmpty { excluded.append(shownIntention) }
        return aiBlockBuddyNextTaskSuggestion(topTitles: topTasks.map { $0.title },
                                              otherTitles: existingTaskTitles,
                                              excluding: excluded)
    }

    private func toggleTaskPicker() {
        taskPickerQuery = ""
        isTaskPickerOpen.toggle()
    }

    /// The dropdown hanging under the current-task row (and a click-away catcher behind it). Sits in the
    /// phase's overlay — not inside the scroll view — so it can float over the buttons.
    @ViewBuilder private var taskPickerOverlay: some View {
        if isTaskPickerOpen {
            ZStack(alignment: .topLeading) {
                Color.clear.contentShape(Rectangle()).onTapGesture { isTaskPickerOpen = false }
                AiBlockBuddyTaskPicker(query: $taskPickerQuery, taskTitles: existingTaskTitles,
                                       maxListHeight: taskPickerListHeight,
                                       onPick: { title in adoptTask(named: title) },
                                       onCancel: { isTaskPickerOpen = false })
                    .frame(width: currentTaskRowFrame.width)
                    .offset(x: currentTaskRowFrame.minX, y: currentTaskRowFrame.maxY + AiBlockBuddyDesign.pickerGap)
            }
        }
    }

    /// Keep the dropdown's list inside the window on short screens.
    private var taskPickerListHeight: CGFloat {
        let room = contentHeight - currentTaskRowFrame.maxY - AiBlockBuddyDesign.pickerGap
            - AiBlockBuddyDesign.compactButtonHeight - AiBlockBuddyDesign.outerPadding
        return max(AiBlockBuddyDesign.compactButtonHeight, min(AiBlockBuddyDesign.pickerMaxListHeight, room))
    }

    /// A task was chosen from the dropdown, or a name typed + Return: show it on the row, close the
    /// dropdown, confirm the change, and hand it to the parent (an existing Day Plan task is adopted,
    /// else a new one is created + adopted); the parent then dismisses and re-checks the caught item.
    private func adoptTask(named name: String) {
        guard let title = AiBlockBuddyTaskChange.committedTitle(name) else { return }
        pickedIntention = title
        isTaskPickerOpen = false
        confirmTaskChange(to: title) { onUpdateCurrentTask(title) }
    }

    private func pick(_ task: DayPlanTask) {
        // Switch to the picked task immediately and let the focus loop re-check the current site against it
        // — it may now be relevant and unblock. Saving what you were doing stays a separate action.
        confirmTaskChange(to: task.title) { onSwitch(task) }
    }

    /// Put "Task changed to <title>" on screen by itself, then commit the change — which dismisses the
    /// check-in. Both ways of changing the task go through here, so neither can vanish unacknowledged.
    private func confirmTaskChange(to title: String, then commit: @escaping () -> Void) {
        changedTaskTitle = title
        phase = .taskChanged
        DispatchQueue.main.asyncAfter(deadline: .now() + AiBlockBuddyTaskChange.confirmationSeconds,
                                      execute: commit)
    }

    /// The confirmation phase: the changed task's name, centred, and nothing else — the point is that
    /// the user sees what they just switched to rather than a window blinking out.
    private var taskChangedView: some View {
        VStack {
            Spacer(minLength: 0)
            Text(AiBlockBuddyText.taskChangedTo(changedTaskTitle))
                .font(buddySemibold(AiBlockBuddyDesign.sectionTitleSize))
                .foregroundColor(AiBlockBuddyPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AiBlockBuddyDesign.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Jump straight to the save form to capture the current activity as a task — no top-task pick,
    /// no block.
    private func beginSaveCurrent() {
        resetSideQuestForm()
        phase = .save
    }

    private func resetSideQuestForm() {
        // Start EMPTY (not the bare domain) and show a spinner while the AI title is generated, so the
        // field doesn't jarringly show "github.com" and then swap.
        sideQuestTitle = ""
        prefilledTitle = ""
        isGuessingTitle = true
        sideQuestDuration = "15"
        sideQuestProject = ""
        sideQuestNotes = defaultNotes
        requestAiTitleGuess()
    }

    /// Kick off the async AI title guess. When it returns, fill the Title field ONLY if the user hasn't
    /// typed their own yet (still equal to what we prefilled) and the save form is still showing —
    /// using the guess, or a sensible fallback (page title, else domain) when the AI fails/returns empty.
    /// Never blocks the UI.
    private func requestAiTitleGuess() {
        onSuggestTitle { guess in
            isGuessingTitle = false
            guard phase == .save, sideQuestTitle == prefilledTitle else { return }
            let resolved = (guess?.isEmpty == false) ? guess! : fallbackTitle()
            sideQuestTitle = resolved
            prefilledTitle = resolved
        }
    }

    /// Title to use when the AI guess is unavailable: prefer the caught page's title, else a tidy
    /// domain/app name — never leave the field empty.
    private func fallbackTitle() -> String {
        let page = pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return page.isEmpty ? defaultSideQuestTitle() : page
    }

    /// A tidy default title for the side-quest from the caught item (strip a URL down to its host).
    private func defaultSideQuestTitle() -> String {
        let trimmed = itemLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if let comps = URLComponents(string: trimmed), let host = comps.host { return host }
        return trimmed
    }

    // MARK: Save side-quest

    /// Whether the form has a non-empty title to save (drives the Save button's enabled state and the
    /// Return-to-save guard).
    private var canSaveTask: Bool {
        !sideQuestTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var saveView: some View {
        // Fields SCROLL; the action button is pinned below so Save is always visible even when the form
        // is taller than the window.
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AiBlockBuddyDesign.fieldGap) {
                    AiBlockBuddyStepHeader(title: AiBlockBuddyText.saveCurrentTitle) { phase = .choose }
                    Text(AiBlockBuddyText.saveCurrentSubtitle)
                        .font(buddyRegular(AiBlockBuddyDesign.sublineSize))
                        .foregroundColor(AiBlockBuddyPalette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    saveFormFields
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AiBlockBuddyDesign.outerPadding)
            }
            SwiftUI.Button(AiBlockBuddyText.saveTaskButton, action: confirmSave)
                .buttonStyle(AiBlockBuddyButtonStyle(kind: .primary))
                .disabled(!canSaveTask)
                .opacity(canSaveTask ? 1 : 0.5)
                .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
                .padding(.bottom, AiBlockBuddyDesign.outerPadding)
        }
    }

    private var saveFormFields: some View {
        VStack(alignment: .leading, spacing: AiBlockBuddyDesign.fieldGap) {
            fieldGroup(AiBlockBuddyText.fieldTitle) {
                HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
                    // Enter in this single-line field commits Save (never dismisses the screen). The
                    // Description TextEditor below keeps Enter for newlines.
                    TextField(isGuessingTitle ? AiBlockBuddyText.titleGeneratingPlaceholder : "",
                              text: $sideQuestTitle, onCommit: saveFromReturnKey)
                        .textFieldStyle(.plain)
                        .font(buddyRegular(AiBlockBuddyDesign.fieldSize))
                    if isGuessingTitle {
                        ProgressView().controlSize(.small)
                    }
                }
                .buddyField()
            }
            fieldGroup(AiBlockBuddyText.fieldDescription) {
                // Multi-line, editable — prefilled with the caught URL so the user keeps a link back to
                // what they were doing. `TextEditor` is macOS 11-safe.
                TextEditor(text: $sideQuestNotes)
                    .font(buddyRegular(AiBlockBuddyDesign.fieldSize))
                    .frame(height: AiBlockBuddyDesign.pt(72))
                    .buddyField()
            }
            HStack(alignment: .top, spacing: AiBlockBuddyDesign.fieldGap) {
                fieldGroup(AiBlockBuddyText.fieldDuration) {
                    TextField("15", text: $sideQuestDuration)
                        .textFieldStyle(.plain)
                        .font(buddyRegular(AiBlockBuddyDesign.fieldSize))
                        .buddyField()
                        .frame(width: AiBlockBuddyDesign.pt(120))
                }
                fieldGroup(AiBlockBuddyText.fieldProject) {
                    // Type-to-filter combo box (not a fixed dropdown): pick an existing project by typing
                    // part of its name, or type a brand-new name to create one.
                    FilteringComboBox(text: $sideQuestProject, allItems: projectNames,
                                      placeholder: AiBlockBuddyText.projectPlaceholder)
                        .frame(height: AiBlockBuddyDesign.compactButtonHeight * 0.6)
                }
            }
        }
    }

    private func fieldGroup<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AiBlockBuddyDesign.cardInnerGap) {
            Text(label)
                .font(buddyMedium(AiBlockBuddyDesign.fieldLabelSize))
                .foregroundColor(AiBlockBuddyPalette.inkMuted)
            content()
        }
    }

    /// Return pressed in the Title field → commit Save, but only when there's a title (never dismiss).
    private func saveFromReturnKey() {
        guard canSaveTask else { return }
        confirmSave()
    }

    /// Build the task from the form, add it to the Day Plan, then return to the check-in.
    private func confirmSave() {
        let title = sideQuestTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let minutes = max(1, Int(sideQuestDuration.trimmingCharacters(in: .whitespaces)) ?? 15)
        let project = sideQuestProject.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = sideQuestNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = DayPlanTask(title: title, durationMinutes: minutes,
                               project: project.isEmpty ? nil : project,
                               notes: notes.isEmpty ? nil : notes)
        onSaveTask(task)
        phase = .choose
    }

    // MARK: Argue with the AI

    // Argue state lives here so it resets when re-entered.
    @SwiftUI.State private var messages: [AiBlockChatMessage] = []
    @SwiftUI.State private var input: String = ""
    @SwiftUI.State private var isThinking = false
    @SwiftUI.State private var relevantApproved = false
    /// The user's chosen time box for the allow (minutes). Seeded from the AI's suggestion on approval,
    /// but the user's picker value always wins.
    @SwiftUI.State private var allowMinutes = kAiBlockDefaultAllowMinutes

    private func beginArgue() {
        messages = []
        input = ""
        relevantApproved = false
        allowMinutes = kAiBlockDefaultAllowMinutes
        phase = .argue
    }

    private var topTaskTitleForArgument: String { topTasks.first?.title ?? "your focus goal" }

    /// The user's stated reason, built from every message they typed in the argue chat (the AI's replies
    /// are excluded). Passed to `onAllow` so it's recorded for later backend URL/app relevance checks.
    private var argueJustification: String {
        messages.filter { $0.role == .user }.map { $0.text }.joined(separator: "\n")
    }

    private var argueView: some View {
        VStack(spacing: 0) {
            AiBlockBuddyStepHeader(title: AiBlockBuddyText.argueHeader) { phase = .choose }
                .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
                .padding(.top, AiBlockBuddyDesign.outerPadding)
            transcript
            if relevantApproved { approvedBar }
            inputBar
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: AiBlockBuddyDesign.cardControlGap) {
                    ForEach(messages) { bubble($0) }
                    if isThinking {
                        HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
                            ProgressView().controlSize(.small)
                            Text(AiBlockBuddyText.argueThinking)
                                .font(buddyRegular(AiBlockBuddyDesign.fieldLabelSize))
                                .foregroundColor(AiBlockBuddyPalette.inkMuted)
                        }.id("thinking")
                    }
                }
                .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
                .padding(.vertical, AiBlockBuddyDesign.fieldGap)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: messages.count) { _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: isThinking) { thinking in
                if thinking { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
            }
        }
    }

    private func bubble(_ message: AiBlockChatMessage) -> some View {
        let isUser = message.role == .user
        return HStack {
            if isUser { Spacer(minLength: AiBlockBuddyDesign.pt(60)) }
            Text(message.text)
                .font(buddyRegular(AiBlockBuddyDesign.chatSize))
                .fixedSize(horizontal: false, vertical: true)
                .padding(AiBlockBuddyDesign.bubblePadding)
                .background(isUser ? AiBlockBuddyPalette.chatUserBubble : AiBlockBuddyPalette.chatBuddyBubble)
                .foregroundColor(isUser ? Color.white : AiBlockBuddyPalette.ink)
                .clipShape(RoundedRectangle(cornerRadius: AiBlockBuddyDesign.bubbleRadius, style: .continuous))
            if !isUser { Spacer(minLength: AiBlockBuddyDesign.pt(60)) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var approvedBar: some View {
        VStack(spacing: AiBlockBuddyDesign.cardControlGap) {
            // Ask how long they need before allowing — a time box, not a permanent pass. The Stepper +
            // typed value both feed `allowMinutes`; the buddy re-checks in after it elapses.
            HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
                Text(AiBlockBuddyText.argueDurationPrompt)
                    .font(buddyRegular(AiBlockBuddyDesign.fieldSize))
                    .foregroundColor(AiBlockBuddyPalette.inkMuted)
                Spacer()
                Stepper(value: $allowMinutes, in: kAiBlockMinAllowMinutes...kAiBlockMaxAllowMinutes) {
                    Text("\(allowMinutes) \(AiBlockBuddyText.argueMinutesUnit)")
                        .font(buddyMedium(AiBlockBuddyDesign.fieldSize))
                        .foregroundColor(AiBlockBuddyPalette.ink)
                }
                .fixedSize()
            }
            SwiftUI.Button(AiBlockBuddyText.argueAllowForButton(clampedAllowMinutes),
                           action: { onAllow(clampedAllowMinutes, argueJustification) })
                .buttonStyle(AiBlockBuddyButtonStyle(kind: .primary, height: AiBlockBuddyDesign.compactButtonHeight))
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
        .padding(.vertical, AiBlockBuddyDesign.fieldGap)
        .background(AiBlockBuddyPalette.accentTint)
    }

    /// The chosen time box, clamped to the allowed range (defends against any out-of-range state).
    private var clampedAllowMinutes: Int {
        min(kAiBlockMaxAllowMinutes, max(kAiBlockMinAllowMinutes, allowMinutes))
    }

    private var inputBar: some View {
        HStack(spacing: AiBlockBuddyDesign.cardControlGap) {
            TextField(AiBlockBuddyText.argueInputPlaceholder, text: $input, onCommit: sendArgument)
                .textFieldStyle(.plain)
                .font(buddyRegular(AiBlockBuddyDesign.fieldSize))
                .buddyField()
            SwiftUI.Button(AiBlockBuddyText.argueSend, action: sendArgument)
                .buttonStyle(AiBlockBuddyButtonStyle(kind: .primary, height: AiBlockBuddyDesign.compactButtonHeight * 0.8,
                                                     fontSize: AiBlockBuddyDesign.fieldSize))
                .frame(width: AiBlockBuddyDesign.pt(110))
                .disabled(isThinking || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, AiBlockBuddyDesign.outerPadding)
        .padding(.vertical, AiBlockBuddyDesign.fieldGap)
    }

    private func sendArgument() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        // Clear on the NEXT runloop: on an `onCommit` (Return) send, AppKit's field editor commits the
        // typed text back into the binding AFTER this handler returns, overwriting a synchronous clear —
        // so the field keeps showing the just-sent message. Deferring past that commit makes it stick.
        DispatchQueue.main.async { input = "" }
        relevantApproved = false
        messages.append(AiBlockChatMessage(role: .user, text: text))
        isThinking = true
        onEvaluate(topTaskTitleForArgument, messages) { result in
            isThinking = false
            switch result {
            case .success(let verdict):
                messages.append(AiBlockChatMessage(role: .buddy, text: verdict.message))
                relevantApproved = verdict.relevant
                if verdict.relevant {
                    // Seed the picker with the AI's suggestion (the user can still change it).
                    allowMinutes = verdict.clampedSuggestedMinutes ?? kAiBlockDefaultAllowMinutes
                }
            case .failure(let error):
                let msg = AiBlockBuddyText.argueError
                messages.append(AiBlockChatMessage(role: .buddy, text: msg.isEmpty ? error.localizedDescription : msg))
                relevantApproved = false
            }
        }
    }
}

// MARK: - Filtering combo box (type-to-filter, pick-or-create)

/// A field the user can TYPE INTO to filter a list of existing items and pick one, or type a brand-new
/// name that isn't in the list. Used for both the project field and the "update your current task" field.
/// SwiftUI's `Picker` is a fixed dropdown that can't do either, so we bridge an `NSComboBox` (free-text
/// editable + a data-source-filtered popup). macOS 11-safe. `onCommit` fires when the user presses Return
/// or clicks a popup item (so choosing an item, or naming a new one and hitting Enter, both confirm).
struct FilteringComboBox: NSViewRepresentable {
    @SwiftUI.Binding var text: String
    let allItems: [String]
    let placeholder: String
    var onCommit: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSComboBox {
        let combo = NSComboBox()
        combo.usesDataSource = true
        combo.dataSource = context.coordinator
        combo.delegate = context.coordinator
        combo.completes = true
        combo.hasVerticalScroller = true
        combo.placeholderString = placeholder
        combo.target = context.coordinator
        combo.action = #selector(Coordinator.comboCommitted(_:))
        context.coordinator.allItems = allItems
        context.coordinator.filtered = allItems
        combo.stringValue = text
        return combo
    }

    func updateNSView(_ combo: NSComboBox, context: Context) {
        context.coordinator.allItems = allItems
        if combo.stringValue != text { combo.stringValue = text }
    }

    final class Coordinator: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
        private let parent: FilteringComboBox
        var allItems: [String] = []
        var filtered: [String] = []

        init(_ parent: FilteringComboBox) {
            self.parent = parent
            self.filtered = parent.allItems
        }

        /// Narrow the popup to items containing what the user typed (empty query = show all).
        private func refilter(for query: String) {
            filtered = query.isEmpty
                ? allItems
                : allItems.filter { $0.localizedCaseInsensitiveContains(query) }
        }

        func numberOfItems(in comboBox: NSComboBox) -> Int { filtered.count }

        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
            index >= 0 && index < filtered.count ? filtered[index] : nil
        }

        func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
            allItems.first { $0.lowercased().hasPrefix(string.lowercased()) }
        }

        func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
            filtered.firstIndex { $0.caseInsensitiveCompare(string) == .orderedSame } ?? NSNotFound
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let combo = obj.object as? NSComboBox else { return }
            parent.text = combo.stringValue
            refilter(for: combo.stringValue)
            combo.reloadData()
            // Surface the substring matches: AppKit won't auto-open the popup while typing, so the
            // filtered list stays hidden (leaving only prefix-only inline completion visible). Expand
            // it ourselves whenever a non-empty query has matches, collapse it when the query clears.
            expandPopUp(combo, query: combo.stringValue)
        }

        /// Programmatically open/close the combo's dropdown so filtered (substring) results are visible
        /// as the user types. Mirrors `searchableComboBox.expandPopUp` (a proven pattern in this app).
        private func expandPopUp(_ combo: NSComboBox, query: String) {
            let shouldExpand = !query.isEmpty && !filtered.isEmpty
            let isExpanded = combo.isAccessibilityExpanded()
            if shouldExpand && !isExpanded {
                combo.cell?.setAccessibilityExpanded(true)
            } else if !shouldExpand && isExpanded {
                combo.cell?.setAccessibilityExpanded(false)
            }
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let combo = notification.object as? NSComboBox else { return }
            let index = combo.indexOfSelectedItem
            guard index >= 0 && index < filtered.count else { return }
            let chosen = filtered[index]
            // Deferred: AppKit hasn't committed the selection to `stringValue` yet at this point.
            DispatchQueue.main.async {
                combo.stringValue = chosen
                self.parent.text = chosen
            }
        }

        /// Return pressed, or a popup item picked → sync the text and notify `onCommit`. Prefer the
        /// selected item (its `stringValue` may not be committed yet at action time) over the typed text.
        @objc func comboCommitted(_ sender: NSComboBox) {
            let index = sender.indexOfSelectedItem
            if index >= 0 && index < filtered.count {
                sender.stringValue = filtered[index]
                parent.text = filtered[index]
            } else {
                parent.text = sender.stringValue
            }
            parent.onCommit?()
        }
    }
}

// MARK: - Chat model

/// One line in the argue-with-the-AI conversation.
struct AiBlockChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    enum Role {
        case buddy, user
        var apiRole: String { self == .buddy ? "assistant" : "user" }
    }
}
