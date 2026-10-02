//
//  FocusStartSimpleScreen.swift
//  Focus Bear
//
//  Figma "0.0/ Flow Start" — the one-dial start screen. Everything except the session length lives on
//  the advanced screen; the "Top Secret / Extra Powerful Options ›" link switches the app into geek
//  mode and lands the user there.
//

import SwiftUI

@available(macOS 11.0, *)
struct FocusStartSimpleScreen: SwiftUI.View {
    @ObservedObject var state: FocusStartState

    var body: some SwiftUI.View {
        GeometryReader { proxy in
            let scale = FocusStartScale(contentWidth: proxy.size.width)
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    Text(state.postponeTitle ?? state.strings.simpleTitle)
                        .font(scale.font(FocusStartLayout.headlineFont, .semibold))
                        .foregroundColor(FocusStartPalette.primaryText)
                        .multilineTextAlignment(.center)
                        // The mode link is overlaid at the same height, so the centred title has to
                        // keep off its gutter — otherwise a long title (Spanish, or a postpone title)
                        // runs underneath "Top Secret / Extra Powerful Options" (#2449). Reserved on
                        // both sides so the title stays centred on the screen, not on what is left.
                        .frame(maxWidth: titleWidth(in: proxy.size.width, scale: scale))
                    bear(scale)
                    Text(state.strings.setSessionLengthLabel)
                        .font(scale.font(FocusStartLayout.panelTitleFont))
                        .foregroundColor(FocusStartPalette.primaryText)
                        .padding(.bottom, scale.pt(24))
                    FocusStartDurationDial(duration: $state.duration,
                                           strings: state.strings,
                                           scale: scale,
                                           isEnabled: state.isDurationEditable)
                    if !state.unfocusedTimerText.isEmpty {
                        Text(state.unfocusedTimerText)
                            .font(scale.font(FocusStartLayout.summaryFont))
                            .foregroundColor(FocusStartPalette.secondaryText)
                            .padding(.top, scale.pt(32))
                    }
                    FocusStartPrimaryButton(title: state.startButtonTitle,
                                            scale: scale,
                                            isEnabled: state.isStartEnabled,
                                            action: state.onStart)
                        .frame(width: scale.pt(1191))
                        .padding(.top, scale.pt(96))
                    if let notice = state.blockingScheduleNotice {
                        Text(notice)
                            .font(scale.font(FocusStartLayout.summaryFont))
                            .foregroundColor(FocusStartPalette.warning)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: scale.pt(1191))
                            // Let the wrapped notice grow vertically rather than clip (#2791).
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, scale.pt(24))
                    }
                    // A running blocking schedule is not a session, so this screen stays available —
                    // it just says what is already being blocked, in the secondary colour so it reads
                    // as status rather than as a problem.
                    if let schedule = state.activeBlockingScheduleText {
                        Text(schedule)
                            .font(scale.font(FocusStartLayout.summaryFont))
                            .foregroundColor(FocusStartPalette.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: scale.pt(1191))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, scale.pt(24))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, scale.pt(FocusStartLayout.titleTopInset))
                .padding(.bottom, scale.pt(FocusStartLayout.screenBottomInset))
                .overlay(header(scale), alignment: .top)
            }
            .background(FocusStartPalette.screenBackground)
        }
    }

    /// How wide the headline may be before it reaches the overlaid mode link's gutter.
    private func titleWidth(in width: CGFloat, scale: FocusStartScale) -> CGFloat {
        max(scale.pt(FocusStartLayout.contentColumnWidth) / 2,
            width - 2 * scale.pt(FocusStartLayout.modeLinkColumnWidth))
    }

    /// The permissions banner (when there is one) on the left, the mode link on the right. Overlaid
    /// on the column so it sits level with the title, the way the design draws it.
    private func header(_ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(alignment: .top, spacing: scale.pt(48)) {
            if let tip = state.permissionsTip {
                FocusStartPermissionsBanner(tip: tip,
                                            buttonTitle: state.strings.fixPermissionsButton,
                                            scale: scale,
                                            action: state.onFixPermissions)
                    .frame(maxWidth: scale.pt(1000), alignment: .leading)
            }
            Spacer(minLength: 0)
            FocusStartModeLink(topLine: state.strings.goAdvancedLinkTop,
                               bottomLine: state.strings.goAdvancedLinkBottom,
                               pointsBack: false,
                               scale: scale,
                               action: state.onSwitchMode)
        }
        .padding(.horizontal, scale.pt(64))
        .padding(.top, scale.pt(123))
    }

    /// The bear in its cream disc with "Ready to focus?" tucked in on the left, as the design draws it.
    private func bear(_ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(spacing: scale.pt(-120)) {
            Text(state.strings.readyToFocusBubble)
                .font(scale.font(FocusStartLayout.bubbleFont))
                .foregroundColor(FocusStartPalette.speechText)
                .padding(.vertical, scale.pt(44))
                .padding(.horizontal, scale.pt(64))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(40))
                        .fill(FocusStartPalette.speechBackground)
                )
                .focusStartShadow(scale, blur: 14)
                .zIndex(1)
            ZStack {
                Circle()
                    .fill(FocusStartPalette.bearHalo)
                    .frame(width: scale.pt(FocusStartLayout.bearCircleDiameter),
                           height: scale.pt(FocusStartLayout.bearCircleDiameter))
                Image("focusStartBearSimple")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: scale.pt(FocusStartLayout.bearWidthSimple))
                    .offset(y: scale.pt(FocusStartLayout.bearDropInDisc))
            }
        }
        .padding(.top, scale.pt(24))
        .padding(.bottom, scale.pt(24))
    }
}
