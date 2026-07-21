//
//  YouTubeMusicPlayerView.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import SwiftUI
import WebKit

/// Embeds a YouTube video/playlist inline within the Focus Music screen (not a separate window) —
/// shown by FocusMusicView whenever a YouTube Music track is playing. Deliberately kept tiny (see
/// FocusMusicView's frame around this) so it can't double as a way to sit and watch YouTube during
/// a focus session — it's meant to confirm something is playing, not to be watchable.
///
/// Loads YouTube's own IFrame Player API (rather than a bare embed URL) so volume/mute can be
/// controlled programmatically from Swift (see applyVolumeAndMuteIfNeeded) — a bare <iframe
/// src=".../embed/...">  has no such hook. This also sidesteps the "Error 153" /
/// PLAYABILITY_ERROR_CODE_EMBEDDER_IDENTITY_MISSING_REFERRER YouTube's embed player returns for a
/// referrer-less top-level WKWebView load: loading real HTML via loadHTMLString(_:baseURL:) gives
/// the page (and the iframe the JS API creates inside it) a proper origin/referrer, exactly like
/// YouTube's own documented IFrame API integration pattern.
struct YouTubeMusicPlayerView: NSViewRepresentable {
    let id: String
    let kind: YouTubeMusicTrack.Kind
    var volume: Float
    var isMuted: Bool

    final class Coordinator {
        var loadedKey: String?
        var lastAppliedVolume: Int?
        var lastAppliedMuted: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Without this, WebKit's default autoplay policy silently blocks (or force-mutes) autoplay
        // that isn't in response to a user gesture — the "Play" click happened in SwiftUI, not
        // inside this webview, so from WebKit's point of view autoplay here has no gesture behind it.
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        loadIfNeeded(in: webView, context: context)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadIfNeeded(in: webView, context: context)
        applyVolumeAndMuteIfNeeded(in: webView, context: context)
    }

    private func loadIfNeeded(in webView: WKWebView, context: Context) {
        // SwiftUI can call updateNSView for unrelated re-renders of the parent view (any @Published
        // change) — only actually reload if the track being shown has changed.
        let key = "\(kind.rawValue):\(id)"
        guard context.coordinator.loadedKey != key else { return }
        context.coordinator.loadedKey = key
        context.coordinator.lastAppliedVolume = nil
        context.coordinator.lastAppliedMuted = nil

        let videoIdLine: String
        let playlistVars: String
        switch kind {
        case .video:
            videoIdLine = "videoId: '\(id)',"
            playlistVars = ""
        case .playlist:
            videoIdLine = ""
            playlistVars = "listType: 'playlist', list: '\(id)',"
        }

        let html = """
        <!DOCTYPE html>
        <html><head><style>
        html,body{margin:0;padding:0;background:#000;overflow:hidden;}
        #player{width:100%;height:100%;}
        </style></head>
        <body>
        <div id="player"></div>
        <script>
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

        var fbPlayer;
        function onYouTubeIframeAPIReady() {
            fbPlayer = new YT.Player('player', {
                height: '100%',
                width: '100%',
                \(videoIdLine)
                playerVars: { autoplay: 1, playsinline: 1, controls: 1, \(playlistVars) },
                events: {
                    'onReady': function(event) {
                        window.fbPlayerReady = true;
                        event.target.playVideo();
                    }
                }
            });
        }
        function fbSetVolume(v) { if (window.fbPlayerReady && fbPlayer.setVolume) fbPlayer.setVolume(v); }
        function fbSetMuted(m) { if (window.fbPlayerReady) { if (m) fbPlayer.mute(); else fbPlayer.unMute(); } }
        </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://dashboard.focusbear.io/"))
    }

    private func applyVolumeAndMuteIfNeeded(in webView: WKWebView, context: Context) {
        let clampedVolume = Int((max(0, min(1, volume)) * 100).rounded())
        if context.coordinator.lastAppliedVolume != clampedVolume {
            context.coordinator.lastAppliedVolume = clampedVolume
            webView.evaluateJavaScript("fbSetVolume(\(clampedVolume));", completionHandler: nil)
        }
        if context.coordinator.lastAppliedMuted != isMuted {
            context.coordinator.lastAppliedMuted = isMuted
            webView.evaluateJavaScript("fbSetMuted(\(isMuted ? "true" : "false"));", completionHandler: nil)
        }
    }
}
