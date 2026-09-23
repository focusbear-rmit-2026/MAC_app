//
//  FocusSessionSideRail.swift
//  Focus Bear
//
//  The left rail of the ongoing-session design (Figma 4:79653): a Focus Music header and a Notes card
//  with a quick brain dump. Both are panels pinned to the window's left edge — rounded on their right
//  side only — as the design draws them.
//
//  Neither is a new feature: the music row reflects and opens the app's existing Focus Music screen
//  (`FocusMusicViewModel.shared` / `leftMenuVc.showAllTracks`), and the brain dump writes through the
//  same `PUT /note` upsert the Notes screen uses (`AllApi.upsertBrainDumpNote`), so a dump typed here
//  is the same note that appears there, on the dashboard and on mobile.
//

import SwiftUI

@available(macOS 11.0, *)
struct FocusSessionSideRail: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale
    @SwiftUI.ObservedObject private var music = FocusMusicViewModel.shared

    /// The rail's panels are 719 design px wide and hug the left edge (Figma 4:79846 / 4:79854).
    static let widthDesignPixels: CGFloat = 719
    private static let musicRowHeightDesignPixels: CGFloat = 178
    private static let brainDumpHeightDesignPixels: CGFloat = 700

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            musicPanel
            notesPanel
            Spacer(minLength: 0)
        }
        .frame(width: scale.pt(Self.widthDesignPixels), alignment: .top)
    }

    // MARK: Focus music

    private var musicPanel: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.rowGap)) {
            SwiftUI.Button(action: store.toggleMusicPanel) {
                HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                    Image(systemName: "music.note").font(scale.font(FocusSessionLayout.sectionFont))
                    VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
                        Text(store.strings.focusMusicLabel).font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                        if store.isMusicPanelExpanded, let title = music.nowPlaying?.title {
                            Text(title).font(scale.font(FocusSessionLayout.badgeFont))
                                .foregroundColor(FocusSessionPalette.accent).lineLimit(1)
                        }
                    }
                    if music.isAnyMusicPlaying {
                        Image(systemName: "waveform").foregroundColor(FocusSessionPalette.accent)
                    }
                    Spacer(minLength: 0)
                    FocusSessionDisclosureChevron(isExpanded: store.isMusicPanelExpanded, scale: scale)
                }.foregroundColor(FocusSessionPalette.primaryText)
            }.buttonStyle(FBButtonStyle()).help(store.strings.focusMusicLabel)
            if store.isMusicPanelExpanded { FocusSessionMusicControls(store: store, scale: scale) }
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
        .frame(maxWidth: .infinity, minHeight: scale.pt(Self.musicRowHeightDesignPixels), alignment: .leading)
        .background(railPanelChrome)
        .onAppear { music.refresh() }
    }

    // MARK: Notes / brain dump

    private var notesPanel: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.rowGap)) {
            SwiftUI.Button(action: store.toggleNotesPanel) {
                HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                    Image(systemName: "note.text")
                        .font(scale.font(FocusSessionLayout.sectionFont))
                        .foregroundColor(FocusSessionPalette.primaryText)
                    Text(store.strings.notesLabel)
                        .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                        .foregroundColor(FocusSessionPalette.primaryText)
                    Spacer(minLength: 0)
                    FocusSessionDisclosureChevron(isExpanded: store.isNotesPanelExpanded, scale: scale)
                }
            }
            .buttonStyle(FBButtonStyle())

            if store.isNotesPanelExpanded {
            Text(store.strings.brainDumpLabel)
                .font(scale.font(FocusSessionLayout.badgeFont, .medium))
                .foregroundColor(FocusSessionPalette.accent)

            brainDumpEditor
            FocusSessionBrainDumpAction(text: store.brainDump, scale: scale)

            SwiftUI.Button(action: store.presentNotesLightbox) {
                HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                    Text(store.strings.seeOtherNotes)
                        .font(scale.font(FocusSessionLayout.rowTitleFont))
                        .foregroundColor(FocusSessionPalette.primaryText)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(scale.font(FocusSessionLayout.bodyFont))
                        .foregroundColor(FocusSessionPalette.primaryText)
                }
                .padding(scale.pt(FocusSessionLayout.cardPadding))
                .background(cardChrome(scale: scale))
            }
            .buttonStyle(FBButtonStyle())
            }
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(railPanelChrome)
    }

    private var brainDumpEditor: some SwiftUI.View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.taskCardCornerRadius))
                .fill(FocusSessionPalette.mutedFill)
                .overlay(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.taskCardCornerRadius))
                        .strokeBorder(FocusSessionPalette.border,
                                      lineWidth: scale.pt(FocusSessionLayout.hairline))
                )
            // #2571 (18): the editor is drawn at full opacity so its caret and text are visible — the
            // old empty-state `.opacity(0.02)` (used to reveal the placeholder behind it) hid the caret
            // and made the field read as non-editable. The placeholder is now a non-hit-testing overlay
            // ON TOP instead, shown only while empty, so typing still works and stays visible.
            TextEditor(text: $store.brainDump)
                .font(scale.font(FocusSessionLayout.bodyFont))
                .padding(scale.pt(FocusSessionLayout.inlineGap))
            if store.brainDump.isEmpty {
                Text(store.strings.brainDumpPlaceholder)
                    .font(scale.font(FocusSessionLayout.bodyFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
                    .padding(scale.pt(FocusSessionLayout.cardPadding))
                    .allowsHitTesting(false)
            }
        }
        .frame(height: scale.pt(Self.brainDumpHeightDesignPixels))
    }

    /// The rail's panels are flush with the window edge, so only their right corners are rounded.
    private var railPanelChrome: some SwiftUI.View {
        FocusSessionRightRoundedShape(radius: scale.pt(FocusSessionLayout.panelCornerRadius))
            .fill(FocusSessionPalette.panelBackground)
            .overlay(
                FocusSessionRightRoundedShape(radius: scale.pt(FocusSessionLayout.panelCornerRadius))
                    .strokeBorder(FocusSessionPalette.border,
                                  lineWidth: scale.pt(FocusSessionLayout.panelHairline))
            )
    }
}

/// A disclosure chevron: down when the panel is open, right when it is collapsed. It toggles the
/// panel in place and never navigates — leaving the session screen mid-session, especially a strict
/// one, is worse than annoying.
@available(macOS 11.0, *)
private struct FocusSessionDisclosureChevron: SwiftUI.View {
    let isExpanded: Bool
    let scale: FocusSessionScale

    var body: some SwiftUI.View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(scale.font(FocusSessionLayout.bodyFont))
            .foregroundColor(FocusSessionPalette.secondaryText)
    }
}

/// A rectangle rounded on its trailing corners only — the design's left-edge panels.
struct FocusSessionRightRoundedShape: InsettableShape {
    var radius: CGFloat
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> FocusSessionRightRoundedShape {
        FocusSessionRightRoundedShape(radius: radius, inset: inset + amount)
    }

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: inset, dy: inset)
        let corner = min(radius, min(bounds.width, bounds.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX - corner, y: bounds.minY))
        path.addArc(center: CGPoint(x: bounds.maxX - corner, y: bounds.minY + corner),
                    radius: corner, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - corner))
        path.addArc(center: CGPoint(x: bounds.maxX - corner, y: bounds.maxY - corner),
                    radius: corner, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        path.closeSubpath()
        return path
    }
}


/// Compact controls share the real playback model. The full library opens above the session.
@available(macOS 11.0, *)
private struct FocusSessionMusicControls: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    @SwiftUI.ObservedObject private var music = FocusMusicViewModel.shared
    let scale: FocusSessionScale

    private var isPlaying: Bool {
        if music.youtubePlayingId != nil { return !music.youtubePaused }
        if music.spotifyPlayingId != nil { return true }
        // #2594: read the @Published localTracks flag, not currentSound?.isPlaying. currentSound is not
        // @Published (so pausing didn't re-render this control) and NSSound.isPlaying isn't reliable after
        // pause(); the track's isPlaying flag is kept in sync by play/pause + refresh(), so the icon flips.
        return music.localTracks.contains(where: { $0.isPlaying })
    }

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.rowGap)) {
            if music.nowPlaying != nil || music.localTracks.contains(where: { $0.isPaused }) {
                SwiftUI.Button(action: { music.handleMediaKeyCommand(.toggle) }) {
                    Label(isPlaying ? store.strings.pauseTooltip : store.strings.resumeTooltip,
                          systemImage: isPlaying ? "pause.fill" : "play.fill")
                }
            }
            if music.localTracks.contains(where: { $0.isFileDownloaded }) {
                Menu(store.strings.musicLibrary) {
                    ForEach(music.localTracks.filter { $0.isFileDownloaded }) { track in
                        SwiftUI.Button(track.name) { music.toggleLocalTrack(atIndex: track.index) }
                    }
                }
            } else { Text(store.strings.musicEmpty).foregroundColor(FocusSessionPalette.secondaryText) }
            HStack {
                Text(store.strings.musicVolume)
                Slider(value: Binding(get: { Double(music.volume) }, set: { music.setVolume(Float($0)) }), in: 0...1)
            }
            SwiftUI.Button { store.activeSheet = .music } label: {
                SwiftUI.Label(store.strings.focusMusicLabel, systemImage: "music.note")
            }
        }.font(scale.font(FocusSessionLayout.rowTitleFont))
    }
}

@available(macOS 11.0, *)
struct FocusSessionMusicSheet: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    var body: some SwiftUI.View {
        VStack(alignment: .leading) {
            HStack {
                Text(store.strings.focusMusicLabel).font(Font(getSemiBoldFont(size: 18)))
                Spacer()
                SwiftUI.Button(store.strings.closeButton) { store.activeSheet = nil }
            }.padding()
            FocusSessionMusicLibrary()
        }.frame(width: 620, height: 560)
    }
}

/// allTracksVc already hosts the existing SwiftUI music library and its localized configuration.
/// Share its playback model, without reparenting the live singleton's view.
@available(macOS 11.0, *)
private struct FocusSessionMusicLibrary: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> allTracksVc { allTracksVc() }
    func updateNSViewController(_ controller: allTracksVc, context: Context) {}
}
