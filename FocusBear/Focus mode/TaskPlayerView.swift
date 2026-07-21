//
//  TaskPlayerView.swift
//  Focus Bear
//
//  SwiftUI shell for the To Do Player screen (taskPlayerVc): a native top bar with two distinct
//  cards — a "Stop focus session" control on the left and a focus-music card on the right (the
//  currently-playing track plus an icon that opens the Focus Music screen) — above the web-rendered
//  player (the WKWebView the controller owns and drives). Per this repo's "new/modified Mac UI is
//  SwiftUI" convention, taskPlayerVc.loadView() hosts this via NSHostingView.
//

import SwiftUI
import WebKit

/// Drives the parts of the top bar that change at runtime. Owned by taskPlayerVc, updated from its
/// lifecycle callbacks (e.g. whether the "Stop focus session" button should show).
final class TaskPlayerHeaderModel: ObservableObject {
    @Published var showEndButton = false
}

/// Embeds the controller-owned WKWebView (so all of taskPlayerVc's existing navigation-delegate / JS
/// bridge / message-handler logic keeps operating on the very same instance).
struct FocusPlayerWebView: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

struct TaskPlayerView: SwiftUI.View {
    @SwiftUI.ObservedObject var headerModel: TaskPlayerHeaderModel
    @SwiftUI.ObservedObject var musicModel: FocusMusicViewModel

    let webView: WKWebView

    // Localised strings, resolved by the controller from config.json.
    var stopFocusSessionLabel: String
    var playFocusMusicTooltip: String
    var changeTrackTooltip: String
    var nowPlayingLabel: String

    // Actions wired to the controller.
    var onEndSession: () -> Void
    var onOpenFocusMusic: () -> Void

    private var brandOrange: Color { Color("dark_OrangeColor") }

    var body: some SwiftUI.View {
        SwiftUI.VStack(spacing: 0) {
            topBar
            SwiftUI.Divider()
            FocusPlayerWebView(webView: webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // [ Stop focus session (secondary, no fill) ]   [ focus-music card (orange) ].
    private var topBar: some SwiftUI.View {
        let nowPlaying = musicModel.nowPlaying
        return SwiftUI.HStack(spacing: 8) {
            if headerModel.showEndButton {
                stopButton
            }
            SwiftUI.Spacer(minLength: 8)
            if let nowPlaying = nowPlaying {
                nowPlayingCard(nowPlaying)
                    .frame(maxWidth: .infinity)
            } else {
                playFocusMusicCard
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // Secondary action — plain, muted, no card fill so it doesn't compete with the music card.
    private var stopButton: some SwiftUI.View {
        SwiftUI.Button(action: onEndSession) {
            SwiftUI.HStack(spacing: 4) {
                Image(systemName: "stop.circle").font(.system(size: 12))
                Text(stopFocusSessionLabel).font(.system(size: 10))
            }
            .foregroundColor(.secondary)
        }
        .buttonStyle(FBButtonStyle())
    }

    @ViewBuilder
    private func nowPlayingCard(_ info: NowPlayingInfo) -> some SwiftUI.View {
        SwiftUI.HStack(spacing: 8) {
            SwiftUI.VStack(alignment: .leading, spacing: 1) {
                Text(nowPlayingLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(brandOrange)
                Text(info.title)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            SwiftUI.Spacer(minLength: 6)
            SwiftUI.Button(action: onOpenFocusMusic) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 14))
                    .foregroundColor(brandOrange)
            }
            .buttonStyle(FBButtonStyle())
            .help(changeTrackTooltip)
        }
        .modifier(CardBackground(color: brandOrange))
    }

    // Nothing playing → a labelled "Play focus music" affordance (icon + text) in its own card.
    private var playFocusMusicCard: some SwiftUI.View {
        SwiftUI.Button(action: onOpenFocusMusic) {
            SwiftUI.HStack(spacing: 5) {
                Image(systemName: "music.note.list").font(.system(size: 13))
                Text(playFocusMusicTooltip).font(.system(size: 11))
            }
            .foregroundColor(brandOrange)
            .modifier(CardBackground(color: brandOrange))
        }
        .buttonStyle(FBButtonStyle())
        .help(playFocusMusicTooltip)
    }
}

/// Shared rounded, tinted card chrome so the top-bar cards read as one visual system.
private struct CardBackground: ViewModifier {
    let color: Color
    func body(content: Content) -> some SwiftUI.View {
        content
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
