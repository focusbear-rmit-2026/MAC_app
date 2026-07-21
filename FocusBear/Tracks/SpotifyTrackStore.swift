//
//  SpotifyTrackStore.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

/// A user-added Spotify track/album/playlist link, played by telling the Spotify app directly
/// (AppleScript) rather than downloaded/played locally like the curated tracks in arrAllTracks.
struct SpotifyTrack: Codable, Identifiable, Equatable {
    /// The `spotify:<kind>:<id>` URI — also the unique identifier (a given link can only be added once).
    let id: String
    var name: String
    let url: String
}

/// Local persistence for user-added Spotify links. Deliberately separate from arrAllTracks/
/// kUserdefaultsAllTracks, which is overwritten wholesale from the backend on every launch.
enum SpotifyTrackStore {
    static func load() -> [SpotifyTrack] {
        guard let data = UserDefaults.standard.data(forKey: kUserdefaultsCustomSpotifyTracks),
              let tracks = try? JSONDecoder().decode([SpotifyTrack].self, from: data) else { return [] }
        return tracks
    }

    static func add(_ track: SpotifyTrack) {
        var tracks = load()
        guard !tracks.contains(where: { $0.id == track.id }) else { return }
        tracks.append(track)
        save(tracks)
    }

    static func remove(_ track: SpotifyTrack) {
        save(load().filter { $0.id != track.id })
    }

    private static func save(_ tracks: [SpotifyTrack]) {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        UserDefaults.standard.set(data, forKey: kUserdefaultsCustomSpotifyTracks)
    }
}

/// Parses a pasted Spotify link (web URL or spotify: URI) into a `spotify:<kind>:<id>` URI.
enum SpotifyLinkParser {
    private static let supportedKinds: Set<String> = ["track", "album", "playlist", "episode", "show"]
    /// Spotify IDs are base62 (alphanumeric); reject anything else so the string is always safe
    /// to interpolate directly into an AppleScript command.
    private static let idCharacters = CharacterSet.alphanumerics

    static func parse(_ input: String) -> (uri: String, kind: String)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("spotify:") {
            let parts = trimmed.split(separator: ":").map(String.init)
            guard parts.count == 3, supportedKinds.contains(parts[1]), isValidId(parts[2]) else { return nil }
            return ("spotify:\(parts[1]):\(parts[2])", parts[1])
        }

        guard let url = URL(string: trimmed), let host = url.host, host.hasSuffix("spotify.com") else { return nil }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else { return nil }
        let kind = components[components.count - 2]
        let id = components[components.count - 1]
        guard supportedKinds.contains(kind), isValidId(id) else { return nil }
        return ("spotify:\(kind):\(id)", kind)
    }

    private static func isValidId(_ id: String) -> Bool {
        !id.isEmpty && id.unicodeScalars.allSatisfy { idCharacters.contains($0) }
    }
}

/// Controls the actual Spotify app via the app's existing safe AppleScript wrapper
/// (runAppleScriptSafely / executeScript in globalFile.swift) — never NSAppleScript directly.
enum SpotifyPlaybackManager {
    static func isSpotifyInstalled() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") != nil
    }

    static func play(uri: String) {
        executeScript(script: "tell application \"Spotify\"\nactivate\nplay track \"\(uri)\"\nend tell")
    }

    static func pause() {
        executeScript(script: "tell application \"Spotify\" to pause")
    }

    static func setVolume(percent: Int) {
        let clamped = min(max(percent, 0), 100)
        executeScript(script: "tell application \"Spotify\" to set sound volume to \(clamped)")
    }
}
