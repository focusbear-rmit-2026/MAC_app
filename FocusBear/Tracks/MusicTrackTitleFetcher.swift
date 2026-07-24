//
//  MusicTrackTitleFetcher.swift
//  Focus Bear
//
//  Resolves a human-readable title for a user-added Spotify / YouTube Music link via each service's
//  public oEmbed endpoint (no auth, no API key) — so the Focus Music list and the To Do Player's
//  "Now Playing" bar show the actual track/playlist name instead of the raw pasted URL.
//

import Foundation

enum MusicTrackTitleFetcher {
    /// Spotify oEmbed: https://open.spotify.com/oembed?url=<link> → { "title": "…" }. Works for
    /// track / album / playlist / episode / show links without authentication.
    static func fetchSpotifyTitle(url: String, completion: @escaping (String?) -> Void) {
        guard let endpoint = URL(string: "https://open.spotify.com/oembed?url=\(percentEncoded(url))") else {
            completion(nil); return
        }
        fetchTitle(from: endpoint, completion: completion)
    }

    /// YouTube oEmbed: https://www.youtube.com/oembed?url=<link>&format=json → { "title": "…" }.
    /// music.youtube.com ids map 1:1 onto youtube.com, which is what oEmbed understands. Playlist
    /// titles resolve for public playlists; auto-generated "RD…" radio mixes may not, in which case
    /// the caller keeps its placeholder.
    static func fetchYouTubeTitle(id: String, kind: YouTubeMusicTrack.Kind, completion: @escaping (String?) -> Void) {
        let target: String
        switch kind {
        case .video: target = "https://www.youtube.com/watch?v=\(id)"
        case .playlist: target = "https://www.youtube.com/playlist?list=\(id)"
        }
        guard let endpoint = URL(string: "https://www.youtube.com/oembed?url=\(percentEncoded(target))&format=json") else {
            completion(nil); return
        }
        fetchTitle(from: endpoint, completion: completion)
    }

    // MARK: -

    private static func fetchTitle(from url: URL, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, _, _ in
            var title: String?
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                title = (json["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            DispatchQueue.main.async { completion(title?.isEmpty == false ? title : nil) }
        }.resume()
    }

    /// Encode the inner link as an opaque query value. `.alphanumerics` over-encodes slightly but is
    /// always safe — the oEmbed servers decode it fine.
    private static func percentEncoded(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? string
    }
}
