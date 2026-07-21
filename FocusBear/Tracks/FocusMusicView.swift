//
//  FocusMusicView.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import SwiftUI

/// The Focus Music screen. Whatever's currently playing (from any of the three sources below)
/// surfaces in a highlighted "Now Playing" card pinned to the top, so it's obvious at a glance
/// what's on instead of having to hunt through three separate lists.
///
/// User-added Spotify links (played through the Spotify app via SpotifyPlaybackManager) and
/// YouTube Music links (played inline via an embedded WKWebView, YouTubeMusicPlayerView) surface
/// above the curated, downloadable track library (arrAllTracks, played locally via NSSound), since
/// a link the user chose to add is more likely what they want to play right now.
struct FocusMusicView: View {
    @SwiftUI.ObservedObject var model: FocusMusicViewModel

    var descriptionText: String
    var volumeLabelText: String
    var nowPlayingLabelText: String
    var sectionTitleSpotify: String
    var sectionTitleYouTube: String
    var sectionTitleLibrary: String
    var spotifyPlaceholder: String
    var youtubePlaceholder: String
    var addButtonText: String
    var youtubeHintText: String
    var addOwnMusicButtonText: String

    // The Spotify/YouTube "paste a link" inputs are hidden behind this by default — most people
    // just want to press play on the curated library, not be greeted by two link input rows.
    @SwiftUI.State private var showAddOwnMusic = false

    private var nowPlaying: NowPlayingInfo? {
        if let track = model.localTracks.first(where: { $0.isPlaying }) {
            return NowPlayingInfo(title: track.name, subtitle: track.subtitle, source: .local)
        }
        if let id = model.spotifyPlayingId, let track = model.spotifyTracks.first(where: { $0.id == id }) {
            return NowPlayingInfo(title: track.name, subtitle: sectionTitleSpotify, source: .spotify(track))
        }
        if let id = model.youtubePlayingId, let track = model.youtubeTracks.first(where: { $0.id == id }) {
            return NowPlayingInfo(title: track.name, subtitle: sectionTitleYouTube, source: .youtube(track))
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let nowPlaying = nowPlaying {
                    nowPlayingSection(nowPlaying)
                }

                Text(descriptionText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(volumeLabelText)
                    Slider(value: Binding(get: { Double(model.volume) }, set: { model.setVolume(Float($0)) }), in: 0...1)
                        .frame(maxWidth: 220)
                }

                if !model.spotifyTracks.isEmpty {
                    spotifySection
                }
                if !model.youtubeTracks.isEmpty {
                    youtubeSection
                }

                if showAddOwnMusic {
                    addSpotifySection
                    addYouTubeSection
                } else {
                    SwiftUI.Button(addOwnMusicButtonText) { showAddOwnMusic = true }
                        .pointingHandCursor()
                }

                librarySection
            }
            .padding(16)
        }
    }

    // MARK: - Now Playing

    @ViewBuilder
    private func nowPlayingSection(_ info: NowPlayingInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nowPlayingLabelText)
                .font(.caption.weight(.semibold))
                .foregroundColor(.accentColor)
            HStack(spacing: 10) {
                nowPlayingArtwork(for: info.source)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title).font(.headline).lineLimit(1)
                    Text(info.subtitle).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                SwiftUI.Button(action: { stop(info.source) }) {
                    Image(systemName: "stop.circle.fill").font(.system(size: 20))
                }.buttonStyle(FBButtonStyle())
            }
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.15))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func nowPlayingArtwork(for source: NowPlayingSource) -> some View {
        switch source {
        case .local:
            if let waveImage = NSImage(named: "audio Wave") {
                AnimatedGIFView(image: waveImage).frame(width: 32, height: 32)
            }
        case .spotify:
            Image(systemName: "music.note").font(.system(size: 18)).frame(width: 32, height: 32)
        case .youtube:
            // The actual (tiny, non-watchable-sized) video player lives here — it must only ever be
            // instantiated once, so it moved out of the YouTube track list below when playing.
            if let playingId = model.youtubePlayingId, let playingKind = model.youtubePlayingKind {
                ZStack(alignment: .bottomTrailing) {
                    YouTubeMusicPlayerView(id: playingId, kind: playingKind, volume: model.volume, isMuted: model.youtubeMuted)
                        .frame(width: 72, height: 40)
                        .cornerRadius(4)
                    SwiftUI.Button(action: { model.toggleYoutubeMute() }) {
                        Image(systemName: model.youtubeMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.white)
                            .padding(2)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(FBButtonStyle())
                    .padding(2)
                }
                .frame(width: 72, height: 40)
            }
        }
    }

    private func stop(_ source: NowPlayingSource) {
        switch source {
        case .local: model.stopLocalTrack()
        case .spotify: model.stopSpotify()
        case .youtube: model.stopYouTube()
        }
    }

    // MARK: - Spotify

    private var spotifySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sectionTitleSpotify).font(.headline)
            SwiftUI.ForEach(model.spotifyTracks) { (track: SpotifyTrack) in
                let isPlaying = model.spotifyPlayingId == track.id
                HStack {
                    SwiftUI.Button(action: { model.toggleSpotifyTrack(track) }) {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    }.buttonStyle(FBButtonStyle())
                    Text(track.name).lineLimit(1).font(.body.weight(isPlaying ? .semibold : .regular))
                    Spacer()
                    SwiftUI.Button(action: { model.removeSpotifyTrack(track) }) {
                        Image(systemName: "trash")
                    }.buttonStyle(FBButtonStyle())
                }
                .padding(.vertical, 3).padding(.horizontal, 5)
                .background(isPlaying ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(4)
            }
            Divider()
        }
    }

    private var addSpotifySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // No commit handler: onCommit: also fires when the field loses focus on macOS, so
                // clicking across to the other field used to "add" a half-typed/empty value and flash
                // the invalid-link warning without the user pressing Add (and the resulting state
                // change stole focus). Adding is the Add button's job only. (.onSubmit is macOS 12+.)
                TextField(spotifyPlaceholder, text: $model.spotifyUrlInput)
                    .textFieldStyle(.roundedBorder)
                SwiftUI.Button(addButtonText, action: model.addSpotifyTrack)
                    .pointingHandCursor()
                    .disabled(model.spotifyUrlInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let error = model.spotifyError {
                Text(error).font(.caption).foregroundColor(.red)
            }
        }
    }

    // MARK: - YouTube Music

    private var youtubeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sectionTitleYouTube).font(.headline)
            SwiftUI.ForEach(model.youtubeTracks) { (track: YouTubeMusicTrack) in
                let isPlaying = model.youtubePlayingId == track.id
                HStack {
                    SwiftUI.Button(action: { model.toggleYouTubeTrack(track) }) {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    }.buttonStyle(FBButtonStyle())
                    Text(track.name).lineLimit(1).font(.body.weight(isPlaying ? .semibold : .regular))
                    Spacer()
                    SwiftUI.Button(action: { model.removeYouTubeTrack(track) }) {
                        Image(systemName: "trash")
                    }.buttonStyle(FBButtonStyle())
                }
                .padding(.vertical, 3).padding(.horizontal, 5)
                .background(isPlaying ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(4)
            }
            if model.youtubePlayingId == nil {
                Text(youtubeHintText).font(.caption).foregroundColor(.secondary)
            }
            Divider()
        }
    }

    private var addYouTubeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // See addSpotifySection: no commit handler — the Add button is the only way to add.
                TextField(youtubePlaceholder, text: $model.youtubeUrlInput)
                    .textFieldStyle(.roundedBorder)
                SwiftUI.Button(addButtonText, action: model.addYouTubeTrack)
                    .pointingHandCursor()
                    .disabled(model.youtubeUrlInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let error = model.youtubeError {
                Text(error).font(.caption).foregroundColor(.red)
            }
        }
    }

    // MARK: - Library

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text(sectionTitleLibrary).font(.headline)
            SwiftUI.ForEach(model.localTracks) { (track: LocalTrackDisplay) in
                LocalTrackRow(track: track, model: model)
                Divider()
            }
        }
    }
}

private struct LocalTrackRow: View {
    let track: LocalTrackDisplay
    @SwiftUI.ObservedObject var model: FocusMusicViewModel

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name).lineLimit(1).font(.body.weight(track.isPlaying ? .semibold : .regular))
                if !track.subtitle.isEmpty {
                    Text(track.subtitle).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if !track.durationText.isEmpty {
                Text(track.durationText).font(.caption).foregroundColor(.secondary)
            }
            if track.isFileDownloading {
                ProgressView().scaleEffect(0.5).frame(width: 16, height: 16)
            } else if !track.isFileDownloaded {
                SwiftUI.Button(action: { model.downloadTrack(atIndex: track.index) }) {
                    Image(systemName: "arrow.down.circle")
                }.buttonStyle(FBButtonStyle())
            }
            if track.isFileDownloaded {
                SwiftUI.Button(action: { model.toggleLocalTrack(atIndex: track.index) }) {
                    Image(systemName: track.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                }.buttonStyle(FBButtonStyle())
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 5)
        .background(track.isPlaying ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if track.isPlaying, let waveImage = NSImage(named: "audio Wave") {
            AnimatedGIFView(image: waveImage).frame(width: 32, height: 32)
        } else if let image = NSImage(contentsOfFile: track.thumbnailPath) {
            Image(nsImage: image).resizable().frame(width: 32, height: 32).cornerRadius(4)
        } else {
            Color.gray.opacity(0.2).frame(width: 32, height: 32).cornerRadius(4)
        }
    }
}

/// Plays an animated GIF. SwiftUI's `Image` draws only the first frame, so the "now playing"
/// audio-wave indicator sat frozen after the SwiftUI rewrite. This wraps an NSImageView with
/// `animates = true` — the same idiom the rest of the app uses for GIFs.
struct AnimatedGIFView: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.image = image
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        // The GIF's natural size is much larger than the 32pt slot it's shown in. Hug tightly and
        // allow compression so the caller's .frame() wins, instead of the intrinsic size inflating it.
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if nsView.image !== image { nsView.image = image }
        nsView.animates = true
    }
}
