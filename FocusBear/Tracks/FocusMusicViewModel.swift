//
//  FocusMusicViewModel.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

/// One row of the curated Focus Music library (arrAllTracks), reshaped into a SwiftUI-friendly,
/// value-typed snapshot. arrAllTracks itself stays the source of truth — other files (menu "now
/// playing" row, auto-pause-during-meetings, etc.) read/write it directly — refresh() re-derives
/// this array from it rather than replacing it.
struct LocalTrackDisplay: Identifiable {
    let index: Int
    let name: String
    let subtitle: String
    let thumbnailPath: String
    let isPlaying: Bool
    let isPaused: Bool
    let isFileDownloaded: Bool
    let isFileDownloading: Bool
    let durationText: String
    var id: Int { index }
}

/// Whichever track is currently playing, unified across the three sources — used to surface a
/// single "Now Playing" card at the top of the screen instead of making the user hunt through
/// three separate lists to see what's actually on.
enum NowPlayingSource {
    case local
    case spotify(SpotifyTrack)
    case youtube(YouTubeMusicTrack)
}

struct NowPlayingInfo {
    let title: String
    let subtitle: String
    let source: NowPlayingSource
}

/// Drives the unified Focus Music screen: the curated/downloadable track library (arrAllTracks,
/// played locally via NSSound), user-added Spotify links (played via SpotifyPlaybackManager /
/// AppleScript), and user-added YouTube Music links (played inline within the screen via
/// YouTubeMusicPlayerView, an embedded WKWebView). Only one of the three ever plays at once.
final class FocusMusicViewModel: NSObject, ObservableObject {
    /// One shared instance so the Focus Music screen, the To Do Player's now-playing bar, and the
    /// auto-start prompt all read/write the same playback state. Creating it is cheap (reads config
    /// + the Spotify/YouTube stores); the heavy pieces (the YouTube WKWebView) live in FocusMusicView,
    /// which is only built when the Focus Music screen is actually opened.
    static let shared = FocusMusicViewModel()

    @Published private(set) var localTracks: [LocalTrackDisplay] = []
    @Published var volume: Float = 1.0

    @Published var spotifyTracks: [SpotifyTrack] = SpotifyTrackStore.load()
    // Editing the field clears any previous invalid-link warning, so a stale error doesn't sit there
    // while the user is fixing the URL. (Guarded so normal typing isn't a state change.)
    @Published var spotifyUrlInput = "" { didSet { if spotifyError != nil { spotifyError = nil } } }
    @Published var spotifyError: String?
    @Published private(set) var spotifyPlayingId: String?

    @Published var youtubeTracks: [YouTubeMusicTrack] = YouTubeMusicTrackStore.load()
    // See spotifyUrlInput — editing clears the stale invalid-link warning.
    @Published var youtubeUrlInput = "" { didSet { if youtubeError != nil { youtubeError = nil } } }
    @Published var youtubeError: String?
    @Published private(set) var youtubePlayingId: String?
    @Published private(set) var youtubePlayingKind: YouTubeMusicTrack.Kind?
    @Published private(set) var youtubeMuted = false

    /// Read directly by other files (e.g. pause/resume-during-meetings) via allTracksVcObj?.currentSound.
    var currentSound: NSSound?

    /// True while any focus music is playing, from any source. The post-session-start music prompt
    /// checks this so it never offers (or auto-starts) a library track over music the user already has
    /// going — starting a local track stops Spotify/YouTube playback.
    var isAnyMusicPlaying: Bool {
        (currentSound?.isPlaying ?? false) || spotifyPlayingId != nil || youtubePlayingId != nil
    }

    private(set) var spotifyInvalidLinkText = "That doesn't look like a Spotify track/album/playlist link."
    private(set) var spotifyNotInstalledText = "Spotify isn't installed on this Mac."
    private(set) var youtubeInvalidLinkText = "That doesn't look like a music.youtube.com link."

    // Source labels used as the "Now Playing" subtitle for the non-local sources.
    private(set) var spotifySourceLabel = "Spotify"
    private(set) var youtubeSourceLabel = "YouTube Music"

    override init() {
        super.init()
        if let focusMusicInfo = configjson.value(forKey: "focusMusicInfo") as? NSDictionary {
            spotifyInvalidLinkText = focusMusicInfo.value(forKey: "spotifyInvalidLinkError") as? String ?? spotifyInvalidLinkText
            spotifyNotInstalledText = focusMusicInfo.value(forKey: "spotifyNotInstalledError") as? String ?? spotifyNotInstalledText
            youtubeInvalidLinkText = focusMusicInfo.value(forKey: "youtubeInvalidLinkError") as? String ?? youtubeInvalidLinkText
            spotifySourceLabel = focusMusicInfo.value(forKey: "sectionTitleSpotify") as? String ?? spotifySourceLabel
            youtubeSourceLabel = focusMusicInfo.value(forKey: "sectionTitleYouTubeMusic") as? String ?? youtubeSourceLabel
        }
        refresh()
        backfillLinkTitles()
    }

    /// Whatever's currently playing, unified across all three sources — nil when nothing is playing.
    /// Reads the @Published playing state, so any SwiftUI view observing this model (the Focus Music
    /// screen and the To Do Player's now-playing bar) updates automatically when playback changes.
    var nowPlaying: NowPlayingInfo? {
        if let track = localTracks.first(where: { $0.isPlaying }) {
            return NowPlayingInfo(title: track.name, subtitle: track.subtitle, source: .local)
        }
        if let id = spotifyPlayingId, let track = spotifyTracks.first(where: { $0.id == id }) {
            return NowPlayingInfo(title: track.name, subtitle: spotifySourceLabel, source: .spotify(track))
        }
        if let id = youtubePlayingId, let track = youtubeTracks.first(where: { $0.id == id }) {
            return NowPlayingInfo(title: track.name, subtitle: youtubeSourceLabel, source: .youtube(track))
        }
        return nil
    }

    // MARK: - arrAllTracks -> localTracks

    func refresh() {
        localTracks = arrAllTracks.enumerated().map { index, track in
            let name = track["name"] as? String ?? ""
            let description = track["description"] as? String ?? ""
            let artist = track["artist"] as? String ?? ""
            let subtitle: String
            if artist.isEmpty {
                subtitle = description
            } else if description.isEmpty {
                subtitle = artist
            } else {
                subtitle = artist + "-" + description
            }

            var durationText = ""
            if let duration = track["duration"] as? Int {
                let (h, m, s) = secondsToHoursMinutesSeconds(seconds: duration)
                durationText = "\(h)" + hoursHText
                durationText += " \(m)" + minutesMText
                durationText += " \(s)" + secondsSText
            }

            return LocalTrackDisplay(
                index: index,
                name: name,
                subtitle: subtitle,
                thumbnailPath: track["thumbnailLocalUrl"] as? String ?? "",
                isPlaying: track["isPlaying"] as? Bool ?? false,
                isPaused: track["isPaused"] as? Bool ?? false,
                isFileDownloaded: track["isFileDownloded"] as? Bool ?? false,
                isFileDownloading: track["isFileDownloading"] as? Bool ?? false,
                durationText: durationText
            )
        }
    }

    // MARK: - Local track playback

    func toggleLocalTrack(atIndex index: Int) {
        guard index >= 0, index < arrAllTracks.count else { return }
        let isPlaying = arrAllTracks[index]["isPlaying"] as? Bool ?? false
        let isPaused = arrAllTracks[index]["isPaused"] as? Bool ?? false
        if isPlaying || isPaused {
            stopLocalTrack()
        } else {
            playLocalTrack(atIndex: index)
        }
    }

    private func playLocalTrack(atIndex index: Int) {
        guard index >= 0, index < arrAllTracks.count else { return }
        stopSpotify()
        stopYouTube()

        for i in 0..<arrAllTracks.count {
            arrAllTracks[i]["isPlaying"] = false
            arrAllTracks[i]["isPaused"] = false
        }
        currentSound?.stop()
        currentSound = nil

        let localUrlString = arrAllTracks[index]["url"] as? String ?? ""
        arrAllTracks[index]["isPlaying"] = true
        currentSound = NSSound(contentsOfFile: localUrlString, byReference: true)
        currentSound?.play()
        currentSound?.volume = volume
        currentSound?.delegate = self

        // Remember the last local track played so the post-session-start focus-music prompt can
        // resume it (see playLastPlayedOrRandomTrack()).
        if let trackId = arrAllTracks[index]["id"] as? String, !trackId.isEmpty {
            UserDefaults.standard.set(trackId, forKey: kUserdefaultsLastPlayedTrackId)
        }

        refresh()
        menuViewControllerObj?.reloadIfNeeded()
    }

    /// Play the last local track the user played (if still downloaded), otherwise a random downloaded
    /// track; no-op if nothing is downloaded. Backs the post-session-start "want to play some focus
    /// music?" prompt (FocusMusicPromptManager) — ported from the pre-SwiftUI allTracksVc so that
    /// feature survives this screen's SwiftUI rewrite.
    func playLastPlayedOrRandomTrack() {
        let downloadedIndices = arrAllTracks.indices.filter { arrAllTracks[$0]["isFileDownloded"] as? Bool ?? false }
        guard !downloadedIndices.isEmpty else { return }
        if let lastPlayedId = UserDefaults.standard.string(forKey: kUserdefaultsLastPlayedTrackId),
           let lastPlayedIndex = downloadedIndices.first(where: { arrAllTracks[$0]["id"] as? String == lastPlayedId }) {
            playLocalTrack(atIndex: lastPlayedIndex)
        } else if let randomIndex = downloadedIndices.randomElement() {
            playLocalTrack(atIndex: randomIndex)
        }
    }

    func stopLocalTrack() {
        guard currentSound != nil else { return }
        currentSound?.stop()
        currentSound = nil
        for i in 0..<arrAllTracks.count {
            arrAllTracks[i]["isPlaying"] = false
            arrAllTracks[i]["isPaused"] = false
        }
        refresh()
        menuViewControllerObj?.reloadIfNeeded()
    }

    func setVolume(_ value: Float) {
        volume = value
        currentSound?.volume = value
        if spotifyPlayingId != nil {
            SpotifyPlaybackManager.setVolume(percent: Int(value * 100))
        }
    }

    func downloadTrack(atIndex index: Int) {
        guard index >= 0, index < arrAllTracks.count else { return }
        arrAllTracks[index]["isFileDownloading"] = true
        refresh()
        let track = arrAllTracks[index]

        let localUrlString = track["url"] as? String ?? ""
        let localUrl = URL(fileURLWithPath: localUrlString)
        let download_urlString = track["download_url"] as? String ?? ""
        let download_url = URL(string: download_urlString)

        let thumbnailLocalUrlString = track["thumbnailLocalUrl"] as? String ?? ""
        let thumbnailLocalUrl = URL(fileURLWithPath: thumbnailLocalUrlString)
        let thumbnail_download_urlString = track["thumbnail_download_url"] as? String ?? ""
        let thumbnail_download_url = URL(string: thumbnail_download_urlString)

        if !FileManager.default.fileExists(atPath: thumbnailLocalUrlString) {
            allApiObject.downloadFileAsync(url: thumbnail_download_url, destinationUrl: thumbnailLocalUrl) { [weak self] _, _ in
                DispatchQueue.main.async { self?.refresh() }
            }
        }

        allApiObject.downloadFileAsync(url: download_url, destinationUrl: localUrl) { [weak self] success, error in
            DispatchQueue.main.async {
                arrAllTracks[index]["isFileDownloading"] = false
                arrAllTracks[index]["isFileDownloded"] = FileManager.default.fileExists(atPath: localUrl.path)
                UserDefaults.standard.set(arrAllTracks, forKey: kUserdefaultsAllTracks)
                self?.refresh()
            }
        }
    }

    // MARK: - Spotify

    func addSpotifyTrack() {
        spotifyError = nil
        // An empty field isn't an invalid link — say nothing rather than warning.
        guard !spotifyUrlInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let (uri, kind) = SpotifyLinkParser.parse(spotifyUrlInput) else {
            spotifyError = spotifyInvalidLinkText
            return
        }
        guard SpotifyPlaybackManager.isSpotifyInstalled() else {
            spotifyError = spotifyNotInstalledText
            return
        }
        // Friendly placeholder until the oEmbed title lookup resolves the real track/playlist name.
        let track = SpotifyTrack(id: uri, name: "\(spotifySourceLabel) \(kind)", url: spotifyUrlInput)
        SpotifyTrackStore.add(track)
        spotifyTracks = SpotifyTrackStore.load()
        let addedUrl = spotifyUrlInput
        spotifyUrlInput = ""
        resolveSpotifyTitle(id: uri, url: addedUrl)
    }

    private func resolveSpotifyTitle(id: String, url: String) {
        MusicTrackTitleFetcher.fetchSpotifyTitle(url: url) { [weak self] title in
            guard let self, let title else { return }
            SpotifyTrackStore.updateName(id: id, name: title)
            self.spotifyTracks = SpotifyTrackStore.load()
        }
    }

    func toggleSpotifyTrack(_ track: SpotifyTrack) {
        spotifyError = nil
        guard SpotifyPlaybackManager.isSpotifyInstalled() else {
            spotifyError = spotifyNotInstalledText
            return
        }
        if spotifyPlayingId == track.id {
            SpotifyPlaybackManager.pause()
            spotifyPlayingId = nil
        } else {
            stopLocalTrack()
            stopYouTube()
            SpotifyPlaybackManager.play(uri: track.id)
            spotifyPlayingId = track.id
        }
    }

    func removeSpotifyTrack(_ track: SpotifyTrack) {
        SpotifyTrackStore.remove(track)
        spotifyTracks = SpotifyTrackStore.load()
        if spotifyPlayingId == track.id { spotifyPlayingId = nil }
    }

    func stopSpotify() {
        guard spotifyPlayingId != nil else { return }
        SpotifyPlaybackManager.pause()
        spotifyPlayingId = nil
    }

    // MARK: - YouTube Music

    func addYouTubeTrack() {
        youtubeError = nil
        // An empty field isn't an invalid link — say nothing rather than warning.
        guard !youtubeUrlInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let parsed = YouTubeMusicLinkParser.parse(youtubeUrlInput) else {
            youtubeError = youtubeInvalidLinkText
            return
        }
        // Friendly placeholder until the oEmbed title lookup resolves the real video/playlist name.
        let placeholder = parsed.kind == .playlist ? "\(youtubeSourceLabel) playlist" : youtubeSourceLabel
        let track = YouTubeMusicTrack(id: parsed.id, kind: parsed.kind, name: placeholder, url: youtubeUrlInput)
        YouTubeMusicTrackStore.add(track)
        youtubeTracks = YouTubeMusicTrackStore.load()
        youtubeUrlInput = ""
        resolveYouTubeTitle(id: parsed.id, kind: parsed.kind)
    }

    private func resolveYouTubeTitle(id: String, kind: YouTubeMusicTrack.Kind) {
        MusicTrackTitleFetcher.fetchYouTubeTitle(id: id, kind: kind) { [weak self] title in
            guard let self, let title else { return }
            YouTubeMusicTrackStore.updateName(id: id, name: title)
            self.youtubeTracks = YouTubeMusicTrackStore.load()
        }
    }

    /// One-time title backfill for links added before the oEmbed lookup existed (their stored name is
    /// still the raw URL). First swaps the raw URL for a friendly placeholder — persisted, so the ugly
    /// URL never shows again and this backfill won't re-match next launch even if the link can't be
    /// resolved (e.g. YouTube Music "RD…" radio mixes aren't public playlists) — then upgrades to the
    /// real title if oEmbed resolves it.
    private func backfillLinkTitles() {
        for track in spotifyTracks where track.name.contains("http") {
            let kind = SpotifyLinkParser.parse(track.url)?.kind ?? ""
            SpotifyTrackStore.updateName(id: track.id, name: kind.isEmpty ? spotifySourceLabel : "\(spotifySourceLabel) \(kind)")
            resolveSpotifyTitle(id: track.id, url: track.url)
        }
        spotifyTracks = SpotifyTrackStore.load()

        for track in youtubeTracks where track.name.contains("http") {
            let placeholder = track.kind == .playlist ? "\(youtubeSourceLabel) playlist" : youtubeSourceLabel
            YouTubeMusicTrackStore.updateName(id: track.id, name: placeholder)
            resolveYouTubeTitle(id: track.id, kind: track.kind)
        }
        youtubeTracks = YouTubeMusicTrackStore.load()
    }

    func toggleYouTubeTrack(_ track: YouTubeMusicTrack) {
        if youtubePlayingId == track.id {
            stopYouTube()
        } else {
            stopLocalTrack()
            stopSpotify()
            youtubePlayingId = track.id
            youtubePlayingKind = track.kind
        }
    }

    func removeYouTubeTrack(_ track: YouTubeMusicTrack) {
        YouTubeMusicTrackStore.remove(track)
        youtubeTracks = YouTubeMusicTrackStore.load()
        if youtubePlayingId == track.id { stopYouTube() }
    }

    func stopYouTube() {
        guard youtubePlayingId != nil else { return }
        youtubePlayingId = nil
        youtubePlayingKind = nil
    }

    func toggleYoutubeMute() {
        youtubeMuted.toggle()
    }
}

extension FocusMusicViewModel: NSSoundDelegate {
    func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
        for i in 0..<arrAllTracks.count {
            if arrAllTracks[i]["isPlaying"] as? Bool == true {
                arrAllTracks[i]["isPlaying"] = false
                arrAllTracks[i]["isPaused"] = false
            }
        }
        currentSound = nil
        refresh()
    }
}
