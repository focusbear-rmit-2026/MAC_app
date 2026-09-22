//
//  FocusStartTokens.swift
//  Focus Bear
//
//  Design tokens for the focus-session START flow (Figma "Overall design system" → 0.x Flow Start /
//  Set Duration / Set Goal / Set Blocking).
//
//  The Figma screenshot is 3456×2234 pixels, including desktop/window/sidebar chrome. Its visible
//  app content is 3351px wide (x=105...3456); the native host already supplies the omitted chrome.
//  Measurements halve to points. The screen also has to survive the app's small
//  (non-full-screen) window, so those points are scaled again by how much narrower the real content
//  view is than the design. Call sites ask for design pixels (`s.pt(32)`) and never hardcode points.
//
//  These deliberately mirror the ongoing-session screen's FocusSession* tokens (PR #2433). The two
//  screens were built on separate branches off main; once both have landed they should collapse into
//  one shared token set — tracked as a follow-up rather than merged here, where it would guarantee a
//  conflict.
//

import SwiftUI

/// Fixed values of the design system: the frame the measurements were authored against, and the
/// bounds we allow the whole screen to be scaled between.
enum FocusStartTokens {
    /// Visible app content in Figma's Coverup frame, excluding the captured desktop/sidebar chrome.
    static let designFrameWidthPixels: CGFloat = 3351
    /// The design was captured on a 2× (Retina) display.
    static let designPixelsPerPoint: CGFloat = 2
    /// The design frame expressed in points — the width at which `scaleFactor` is exactly 1.
    static let designWidthPoints = designFrameWidthPixels / designPixelsPerPoint

    /// Below this the type gets too small to read, so the screen stops shrinking and scrolls instead.
    static let minimumScaleFactor: CGFloat = 0.62
    /// Never render larger than the design — on a wider-than-design display the content centres.
    static let maximumScaleFactor: CGFloat = 1.0

    /// How much of the design's width one point of the real content view is worth.
    static func scaleFactor(forContentWidth width: CGFloat) -> CGFloat {
        guard width > 0 else { return maximumScaleFactor }
        return min(maximumScaleFactor, max(minimumScaleFactor, width / designWidthPoints))
    }
}

/// Converts design measurements to points for one particular window size. Held in the view tree so a
/// resize re-derives every dimension from a single number.
struct FocusStartScale {
    let factor: CGFloat

    init(contentWidth: CGFloat) {
        factor = FocusStartTokens.scaleFactor(forContentWidth: contentWidth)
    }

    /// Artwork can shrink a little further than form controls; its 40px speech text stays at least 11pt.
    init(decorationFactor: CGFloat) {
        factor = min(FocusStartTokens.maximumScaleFactor, max(0.55, decorationFactor))
    }

    /// Like `init(decorationFactor:)` but with a caller-chosen lower bound. The advanced screen's side
    /// bear needs to fit a tight, centred side column, so it may go below the readable 0.55 floor
    /// rather than disappear entirely (#2571 3).
    init(decorationFactor: CGFloat, minimum: CGFloat) {
        factor = min(FocusStartTokens.maximumScaleFactor, max(minimum, decorationFactor))
    }

    /// A length authored in the design, in points at the current window size.
    func pt(_ designPixels: CGFloat) -> CGFloat {
        designPixels / FocusStartTokens.designPixelsPerPoint * factor
    }

    /// A font whose size was authored in the design.
    ///
    /// Routed through the app's own font helpers rather than `.system(size:)`: Focus Bear lets a user
    /// pick Intel One Mono or OpenDyslexic app-wide, and a screen that hardcodes the system face
    /// silently opts out of that. On the default setting these return the system face, which is the
    /// SF Pro the design specifies.
    func font(_ designPixels: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let size = pt(designPixels)
        let resolved: NSFont
        switch weight {
        case .bold, .heavy, .black: resolved = getBoldFont(size: size)
        case .semibold: resolved = getSemiBoldFont(size: size)
        case .medium: resolved = getMediumFont(size: size)
        default: resolved = getRegularFont(size: size)
        }
        return Font(resolved as CTFont)
    }
}

/// Named layout constants, in design pixels. Keeps the recurring card/gap/radius numbers out of the
/// view bodies so the whole screen can be re-proportioned from one place.
enum FocusStartLayout {
    /// Width of the centre column: title, accordion cards and the Start button all share it.
    static let contentColumnWidth: CGFloat = 1367

    static let cardCornerRadius: CGFloat = 60
    static let controlCornerRadius: CGFloat = 34
    static let fieldCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 20
    static let badgeCornerRadius: CGFloat = 16

    static let cardBorder: CGFloat = 3.9
    static let fieldBorder: CGFloat = 4

    static let cardPadding: CGFloat = 47
    static let cardBottomPadding: CGFloat = 64
    static let collapsedCardBottomPadding: CGFloat = 48
    static let cardInnerPadding: CGFloat = 42
    static let cardStackGap: CGFloat = 51
    static let cardContentGap: CGFloat = 41
    static let rowGap: CGFloat = 27
    static let inlineGap: CGFloat = 16
    static let tightGap: CGFloat = 8

    /// Width reserved for the "Go back / Regular Options" link column. The link itself is fixed-size
    /// (it must never wrap mid-word), so this is what the screen budgets for it when deciding whether
    /// the bear still fits alongside the cards — see FocusStartAdvancedScreen.showsBear.
    static let modeLinkColumnWidth: CGFloat = 760
    /// Advanced form starts at x=1044 inside the screenshot's x=105 content region. Removing
    /// the 24px column gap leaves 915px; the simple screen keeps its separate overlay gutter.
    static let advancedModeLinkColumnWidth: CGFloat = 915

    static let titleTopInset: CGFloat = 195
    static let cardStackTopInset: CGFloat = 76
    static let screenBottomInset: CGFloat = 96

    static let primaryButtonHeight: CGFloat = 137
    static let fieldHeight: CGFloat = 97
    static let smallFieldHeight: CGFloat = 82

    static let stepperDiameter: CGFloat = 105
    static let sliderTrackWidth: CGFloat = 868
    static let sliderTrackHeight: CGFloat = 47
    static let sliderThumbWidth: CGFloat = 89
    static let sliderThumbHeight: CGFloat = 99
    static let sliderThumbCornerRadius: CGFloat = 26

    static let toggleWidth: CGFloat = 105
    static let toggleHeight: CGFloat = 57
    static let toggleKnob: CGFloat = 40
    static let radioDiameter: CGFloat = 48

    static let cardIcon: CGFloat = 60
    static let chevron: CGFloat = 60

    static let bearCircleDiameter: CGFloat = 706
    static let bearWidthSimple: CGFloat = 506
    /// How far below the disc's centre the simple screen's bear hangs, so its hat clears the top edge.
    static let bearDropInDisc: CGFloat = -8.5
    static let bearWidthAdvanced: CGFloat = 533
    static let speechBubbleWidth: CGFloat = 682

    static let headlineFont: CGFloat = 96
    static let panelTitleFont: CGFloat = 64
    static let cardTitleFont: CGFloat = 48
    static let bodyFont: CGFloat = 48
    static let summaryFont: CGFloat = 36
    static let fieldFont: CGFloat = 40
    static let buttonFont: CGFloat = 40
    static let bubbleFont: CGFloat = 40
    static let badgeFont: CGFloat = 24
    static let sliderBoundFont: CGFloat = 47
    static let durationNumberFont: CGFloat = 160
    static let durationUnitFont: CGFloat = 80
}

/// Colours of the screen. The design's surfaces are plain white with a zinc-200 hairline (#E4E4E7);
/// scoped color assets preserve the Figma light/dark tokens without recoloring the rest of the app.
enum FocusStartPalette {
    /// Scoped Figma tokens: preserve the exact focus-screen accent without recoloring other screens.
    static let accent = Color("focusStartAccent")
    static let surface = Color("focusStartCardBackground")
    static let screenBackground = Color("focusStartScreenBackground")
    /// #E4E4E7 — the card hairline. `separatorColor` reads far heavier, so this is mixed by hand and
    /// darkened for dark mode via the dynamic `grayBorderColor` asset where it exists.
    static let border = Color("focusStartBorder")
    /// #FAFAFA — the fill behind dropdowns, steppers and the search fields.
    static let fieldFill = Color("focusStartFieldBackground")
    static let primaryText = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    /// #71717A — the design's zinc-500, used for the "hr"/"min" units and the slider bounds.
    static let mutedText = Color(NSColor.secondaryLabelColor)
    /// The outline of an interactive, unselected control — a radio ring or a toggle track. Deliberately
    /// heavier than `border`: that is a card hairline, and at hairline contrast a radio row reads as
    /// greyed out (#2449).
    static let controlBorder = Color(NSColor.secondaryLabelColor).opacity(0.55)
    /// Supporting text under a control — a description or an explainer. Full-strength `secondaryText`
    /// rather than primary-at-half-opacity, which fell below the enabled-control contrast the radio
    /// options need.
    static let supportingText = Color(NSColor.secondaryLabelColor)
    /// rgba(113,113,122,0.2) — the unfilled slider track.
    static let trackFill = Color(NSColor.secondaryLabelColor).opacity(0.2)
    /// #FFEBD3 — the slider thumb.
    static let thumbFill = Color("focusStartSelection")
    /// Selection stays cream in both appearances, so its metadata must stay dark too.
    static let selectionText = Color(NSColor(calibratedRed: 85/255, green: 85/255, blue: 85/255, alpha: 1))
    /// #FFF7EB — the disc behind the bear.
    static let bearHalo = Color("focusStartHalo")
    static let speechBackground = Color("focusStartSpeechBackground")
    static let speechText = Color(NSColor(calibratedRed: 16/255, green: 16/255, blue: 20/255, alpha: 1))
    static let secondaryAccent = Color("focusStartSecondaryAccent")
    static let metadataBackground = Color("focusStartMetadataBackground")
    static let cardShadow = Color.black.opacity(0.1)
    static let warning = Color(NSColor.systemRed)
}

@available(macOS 11.0, *)
extension SwiftUI.View {
    /// Figma "Light/Normal Shadow" — 20px blur, no offset — at the current scale.
    func focusStartShadow(_ scale: FocusStartScale, blur: CGFloat = 20) -> some SwiftUI.View {
        shadow(color: FocusStartPalette.cardShadow, radius: scale.pt(blur) / 2, x: 0, y: 0)
    }
}
