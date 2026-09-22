//
//  FocusSessionTokens.swift
//  Focus Bear
//
//  Design tokens for the ongoing-focus-session screen (Figma "Sid Focus Bear" → 1. Ongoing Session).
//
//  The Figma screenshot is 3456×2234 pixels, but its app content starts at x=105 below the
//  desktop/window chrome. Only the 3351px content region belongs to this hosted screen. The app
//  already supplies that chrome; including it again skews column proportions and resize thresholds.
//  Measurements halve to points, then adapt to the real content viewport. The app's small
//  (non-full-screen) window, so those points are scaled again by how much narrower the real content
//  view is than the design. Call sites ask for design pixels (`s.pt(32)`) and never hardcode points.
//

import AppKit
import SwiftUI

/// Fixed values of the design system: the frame the measurements were authored against, and the
/// bounds we allow the whole screen to be scaled between.
enum FocusSessionTokens {
    /// Visible app content in Figma 4:79655, excluding the captured desktop/sidebar chrome.
    static let designFrameWidthPixels: CGFloat = 3351
    /// The design was captured on a 2× (Retina) display.
    static let designPixelsPerPoint: CGFloat = 2
    /// The design frame expressed in points — the width at which `scaleFactor` is exactly 1.
    static let designWidthPoints = designFrameWidthPixels / designPixelsPerPoint

    /// Below this the type gets too small to read, so the screen stops shrinking and scrolls instead.
    /// The design is authored for a full-screen 1728pt window; at the app's default window width this
    /// floor keeps the title around 20pt and the countdown around 30pt rather than shrinking them
    /// proportionally into illegibility.
    static let minimumScaleFactor: CGFloat = 0.62
    /// Never render larger than the design — on a wider-than-design display the content centres.
    static let maximumScaleFactor: CGFloat = 1.0
    /// Badges and secondary labels must stay readable when the geometry reaches its compact floor.
    static let minimumFontPoints: CGFloat = 11

    /// How much of the design's width one point of the real content view is worth.
    static func scaleFactor(forContentWidth width: CGFloat) -> CGFloat {
        guard width > 0 else { return maximumScaleFactor }
        return min(maximumScaleFactor, max(minimumScaleFactor, width / designWidthPoints))
    }
}

/// How tall the session's modal panels are allowed to be.
///
/// The Figma panels are authored at a fixed 1509 design pixels — 754.5pt at 1× — which is taller than
/// the usable height of a 1280×800-class display, so the bottom of the panel (Cancel, then the
/// create/save button) sat off the screen entirely (report 2026-09-17_12-59-15). Scrolling could not
/// reach it: the form inside was already in a `ScrollView`; what overflowed was the panel itself. So the
/// panel is capped to the screen it opens on, which keeps its pinned footer visible and hands the
/// overflow to the scroll view that was there for exactly that.
enum FocusSessionSheetMetrics {
    /// Height the task and notes panels are authored at, in design pixels.
    static let designHeightPixels: CGFloat = 1509
    /// Room left between the panel and the edges of the screen, for the window's own chrome and shadow.
    static let screenMarginPoints: CGFloat = 40
    /// Below this the panel has no usable form area left, so it stops shrinking with the screen. At this
    /// floor the header and the footer buttons still fit and the fields scroll between them.
    static let minimumHeightPoints: CGFloat = 320

    /// The height for a panel authored at `designPixels`, given the usable height of the screen it opens
    /// on. Never taller than the design, never taller than the screen, never below the usable floor.
    /// A non-positive `visibleScreenHeight` means "screen unknown" and leaves the design height alone.
    static func height(designPixels: CGFloat,
                       scale: FocusSessionScale,
                       visibleScreenHeight: CGFloat) -> CGFloat {
        let designHeight = scale.pt(designPixels)
        guard visibleScreenHeight > 0 else { return designHeight }
        return max(minimumHeightPoints, min(designHeight, visibleScreenHeight - screenMarginPoints))
    }

    /// Usable height of the screen the app's window is on. `visibleFrame` already excludes the menu bar
    /// and the Dock, which is what "usable" has to mean here. 0 when there is no screen to ask.
    static func visibleScreenHeight() -> CGFloat {
        let screen = NSApp.keyWindow?.screen ?? NSApp.mainWindow?.screen ?? NSScreen.main
        return screen?.visibleFrame.height ?? 0
    }
}

@available(macOS 11.0, *)
extension SwiftUI.View {
    /// Sizes one of the session's modal panels: the design width, and a height capped to the screen.
    func focusSessionSheetFrame(widthDesignPixels: CGFloat, scale: FocusSessionScale) -> some SwiftUI.View {
        frame(width: scale.pt(widthDesignPixels),
              height: FocusSessionSheetMetrics.height(designPixels: FocusSessionSheetMetrics.designHeightPixels,
                                                      scale: scale,
                                                      visibleScreenHeight: FocusSessionSheetMetrics.visibleScreenHeight()))
    }
}

/// Converts design measurements to points for one particular window size. Held in the view tree so a
/// resize re-derives every dimension from a single number.
struct FocusSessionScale {
    let factor: CGFloat

    init(contentWidth: CGFloat) {
        factor = FocusSessionTokens.scaleFactor(forContentWidth: contentWidth)
    }

    /// A length authored in the design, in points at the current window size.
    func pt(_ designPixels: CGFloat) -> CGFloat {
        designPixels / FocusSessionTokens.designPixelsPerPoint * factor
    }

    /// A font whose size was authored in the design.
    ///
    /// Routed through the app's own font helpers rather than `.system(size:)`: Focus Bear lets a user
    /// pick Intel One Mono or OpenDyslexic app-wide, and a screen that hardcodes the system face
    /// silently opts out of that (an accessibility regression for the OpenDyslexic setting). On the
    /// default setting these return the system face, which is the SF Pro the design specifies.
    func font(_ designPixels: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let size = max(FocusSessionTokens.minimumFontPoints, pt(designPixels))
        let resolved: NSFont
        switch weight {
        case .bold: resolved = getBoldFont(size: size)
        case .semibold, .heavy, .black: resolved = getSemiBoldFont(size: size)
        case .medium: resolved = getMediumFont(size: size)
        default: resolved = getRegularFont(size: size)
        }
        return Font(resolved as CTFont)
    }
}

/// Named layout constants, in design pixels. Keeps the recurring card/gap/radius numbers out of the
/// view bodies so the whole screen can be re-proportioned from one place.
enum FocusSessionLayout {
    static let panelCornerRadius: CGFloat = 60
    static let cardCornerRadius: CGFloat = 20
    static let taskCardCornerRadius: CGFloat = 31
    static let hairline: CGFloat = 4
    static let panelHairline: CGFloat = 3.9

    static let screenPadding: CGFloat = 64
    static let panelPadding: CGFloat = 47
    static let cardPadding: CGFloat = 24
    static let cardPaddingLeading: CGFloat = 36
    static let taskCardPadding: CGFloat = 38

    static let sectionGap: CGFloat = 60
    /// Vertical rhythm inside the session card when the window is short.
    static let compactPanelPadding: CGFloat = 28
    static let cardGap: CGFloat = 24
    static let rowGap: CGFloat = 16
    static let inlineGap: CGFloat = 12
    static let tightGap: CGFloat = 8

    /// The source panel extends beyond the screenshot. Its visible region is x=2438...3456;
    /// using the overflowing 1367px node width steals space from the center session card.
    static let optionsPanelWidth: CGFloat = 1018
    static let columnGap: CGFloat = 84
    static let contentTopPadding: CGFloat = 110
    static let sidePanelTopOffset: CGFloat = 92
    static let timerControlDiameter: CGFloat = 233
    static let adjustControlDiameter: CGFloat = 192
    static let progressBarHeight: CGFloat = 27
    static let menuButtonWidth: CGFloat = 96
    static let primaryButtonHeight: CGFloat = 102
    /// A button sized to its label rather than the full card width.
    static let compactButtonHeight: CGFloat = 76

    static let headlineFont: CGFloat = 96
    static let titleFont: CGFloat = 64
    static let sectionFont: CGFloat = 48
    static let taskTitleFont: CGFloat = 50
    static let bodyFont: CGFloat = 36
    static let rowTitleFont: CGFloat = 32
    static let badgeFont: CGFloat = 24
}

/// Layout is based on the usable app viewport, not a desktop screenshot's fixed point height.
/// At narrower widths all artwork shrinks, so a 720pt-high window can still fit the full design.
struct FocusSessionViewportLayout {
    let scale: FocusSessionScale
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    let isWide: Bool
    let isCompact: Bool

    init(size: CGSize) {
        contentWidth = min(max(0, size.width), FocusSessionTokens.designWidthPoints)
        scale = FocusSessionScale(contentWidth: contentWidth)
        isWide = contentWidth >= 1100
        // A stacked page always puts the active task first; a tall desktop's height is not a
        // reason to bury the task below the bear on a narrow sidebar-constrained viewport.
        isCompact = !isWide || size.height < scale.pt(1800)
        contentHeight = max(0, size.height - scale.pt(FocusSessionLayout.contentTopPadding
                                                    + FocusSessionLayout.screenPadding))
    }

    var showsSideRail: Bool { isWide && !isCompact }
    var sidePanelTopOffset: CGFloat { isCompact ? 0 : scale.pt(FocusSessionLayout.sidePanelTopOffset) }
    var taskPanelWidth: CGFloat { scale.pt(FocusSessionLayout.optionsPanelWidth) }
    var sessionColumnWidth: CGFloat {
        let rail = showsSideRail ? scale.pt(FocusSessionSideRail.widthDesignPixels) : scale.pt(FocusSessionLayout.screenPadding)
        let gaps = scale.pt(FocusSessionLayout.columnGap) * (showsSideRail ? 2 : 1)
        return max(0, contentWidth - rail - taskPanelWidth - gaps - scale.pt(FocusSessionLayout.screenPadding))
    }
}

/// Layout decisions for the short-window (compact) form of the session screen, kept as plain
/// arithmetic so they can be unit-tested without building a view tree.
enum FocusSessionCompactLayout {
    /// Narrower than this — measured on the space the row actually gets, not the window — the bear and
    /// the timing card stop fitting beside each other, so the bear is dropped rather than squashed
    /// into a sliver. Below it the screen falls back to the full-width card it had before.
    ///
    /// The binding constraint is the card's control row (-5, pause, +5): at half of this width the card
    /// still has about 40pt of slack around those controls at the minimum scale factor.
    static let sideBySideMinimumWidth: CGFloat = 560

    /// How wide to draw the bear beside the timing card in a short window, or nil to leave it out.
    ///
    /// The user asked for the timing card at half width with the bear beside it on the LEFT, rather
    /// than the bear being dropped outright when the window is short: the card gives up horizontal
    /// space, which is what is spare here, instead of the bear eating vertical space, which is what is
    /// scarce. Note this deliberately departs from the Figma frames, which put the illustration on the
    /// right — the user's description wins over the design where the two disagree.
    ///
    /// The bear never draws larger than its design size, so on a wide-but-short window it stays put and
    /// the card simply keeps the rest of the row.
    static func bearWidth(availableWidth: CGFloat, scale: FocusSessionScale) -> CGFloat? {
        guard availableWidth >= sideBySideMinimumWidth else { return nil }
        let half = (availableWidth - scale.pt(FocusSessionLayout.cardGap)) / 2
        guard half > 0 else { return nil }
        return min(half, scale.pt(FocusSessionBearArtwork.width))
    }
}

/// Colours of the screen.
///
/// The design's surfaces are plain white with a zinc-200 hairline (#E4E4E7) — not the window's grey
/// and not the system separator, both of which read far heavier. Those two live in the asset
/// catalogue (`focusSessionSurfaceColor`, `focusSessionBorderColor`) so they follow light/dark.
/// Accent and score colours are scoped assets matching the fetched Figma variables.
enum FocusSessionPalette {
    static let accent = Color("focusSessionAccentColor")
    static let surface = Color("focusSessionSurfaceColor")
    static let panelBackground = surface
    static let screenBackground = surface
    static let cardBackground = surface
    static let border = Color("focusSessionBorderColor")
    static let primaryText = Color(NSColor.labelColor)
    /// Label colour for a chip filled with `primaryText` — inverted so it reads in both appearances.
    static let invertedText = surface
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    /// The design's zinc-500 at 5% — the dashed "add" rows and secondary buttons.
    static let mutedFill = Color("focusSessionMutedColor").opacity(0.05)
    /// Figma accent #2, scoped so unrelated screens keep their own palette.
    static let scoreBadge = Color("focusSessionScoreBadgeColor")
    static let destructive = Color(NSColor.systemRed)
    /// The ellipse under the bear illustration (#27272A at 20%).
    static let bearShadow = Color("focusSessionBearShadowColor").opacity(0.2)
    /// The design's card/panel drop shadow: 0 0 20px rgba(0,0,0,0.1).
    static let cardShadow = Color.black.opacity(0.1)
}

/// The soft drop shadow the design puts under every card, panel and circular control.
enum FocusSessionShadow {
    /// Figma "Light/Normal Shadow" — 20px blur, no offset.
    static let cardBlurDesignPixels: CGFloat = 20
    /// The heavier shadow on the round timer controls — 40px blur.
    static let controlBlurDesignPixels: CGFloat = 40
}

@available(macOS 11.0, *)
extension SwiftUI.View {
    /// Applies the design's drop shadow at the current scale.
    func focusSessionShadow(_ scale: FocusSessionScale, blur: CGFloat = FocusSessionShadow.cardBlurDesignPixels) -> some SwiftUI.View {
        shadow(color: FocusSessionPalette.cardShadow, radius: scale.pt(blur) / 2, x: 0, y: 0)
    }
}
