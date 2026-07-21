//
//  YouTubeMusicTrackStore.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

/// A user-added music.youtube.com link, played inline within the Focus Music screen
/// (YouTubeMusicPlayerView) rather than downloaded/played locally like the curated tracks in
/// arrAllTracks.
struct YouTubeMusicTrack: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case video
        case playlist
    }

    /// The video id, or the playlist id when kind == .playlist — also the unique identifier (a given
    /// video/playlist can only be added once).
    let id: String
    let kind: Kind
    var name: String
    let url: String
}

/// Local persistence for user-added YouTube Music links. Deliberately separate from arrAllTracks/
/// kUserdefaultsAllTracks, which is overwritten wholesale from the backend on every launch.
enum YouTubeMusicTrackStore {
    static func load() -> [YouTubeMusicTrack] {
        guard let data = UserDefaults.standard.data(forKey: kUserdefaultsYouTubeMusicTracks),
              let tracks = try? JSONDecoder().decode([YouTubeMusicTrack].self, from: data) else { return [] }
        return tracks
    }

    static func add(_ track: YouTubeMusicTrack) {
        var tracks = load()
        guard !tracks.contains(where: { $0.id == track.id }) else { return }
        tracks.append(track)
        save(tracks)
    }

    static func remove(_ track: YouTubeMusicTrack) {
        save(load().filter { $0.id != track.id })
    }

    private static func save(_ tracks: [YouTubeMusicTrack]) {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        UserDefaults.standard.set(data, forKey: kUserdefaultsYouTubeMusicTracks)
    }
}

/// Parses a pasted **music.youtube.com** link — a single-video link (music.youtube.com/watch?v=...
/// or an /embed/ link) or a playlist link (music.youtube.com/playlist?list=..., including the
/// "RD..." auto-generated radio/mix links YouTube Music's own "Share" button produces, which have
/// no video id at all — only a list= parameter) — into an id safe to interpolate directly into an
/// embed URL. Deliberately does NOT accept plain youtube.com or youtu.be links — this is a focus
/// music feature, not a general "watch any YouTube video" one.
enum YouTubeMusicLinkParser {
    struct ParsedLink {
        let id: String
        let kind: YouTubeMusicTrack.Kind
    }

    private static let idCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-")

    static func parse(_ input: String) -> ParsedLink? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), let host = url.host else { return nil }
        guard host == "music.youtube.com" || host.hasSuffix(".music.youtube.com") else { return nil }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        if let v = queryItems.first(where: { $0.name == "v" })?.value, isValidVideoId(v) {
            return ParsedLink(id: v, kind: .video)
        }
        if url.path.hasPrefix("/embed/"), let id = url.pathComponents.last, isValidVideoId(id) {
            return ParsedLink(id: id, kind: .video)
        }
        // A playlist link has no single video id — the list= parameter alone identifies it.
        if let list = queryItems.first(where: { $0.name == "list" })?.value, isValidPlaylistId(list) {
            return ParsedLink(id: list, kind: .playlist)
        }
        return nil
    }

    private static func isValidVideoId(_ id: String) -> Bool {
        id.count == 11 && id.unicodeScalars.allSatisfy { idCharacters.contains($0) }
    }

    /// Playlist ids vary in length ("PL..." user playlists are ~34 chars, "RD..." auto-generated
    /// radio/mix playlists are longer) — just validate the character set, which is what makes it
    /// safe to interpolate into a URL.
    private static func isValidPlaylistId(_ id: String) -> Bool {
        !id.isEmpty && id.unicodeScalars.allSatisfy { idCharacters.contains($0) }
    }
}
