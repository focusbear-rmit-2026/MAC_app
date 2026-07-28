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
    /// titles resolve for public playlists; oEmbed returns nothing for some (unlisted playlists, and
    /// auto-generated "RD…" radio mixes) — for those we fall back to scraping the playlist page's
    /// og:title before giving up and leaving the caller's placeholder.
    static func fetchYouTubeTitle(id: String, kind: YouTubeMusicTrack.Kind, completion: @escaping (String?) -> Void) {
        let target: String
        switch kind {
        case .video: target = "https://www.youtube.com/watch?v=\(id)"
        case .playlist: target = "https://www.youtube.com/playlist?list=\(id)"
        }
        guard let endpoint = URL(string: "https://www.youtube.com/oembed?url=\(percentEncoded(target))&format=json") else {
            completion(nil); return
        }
        fetchTitle(from: endpoint) { oembedTitle in
            if let oembedTitle = oembedTitle { completion(oembedTitle); return }
            // oEmbed couldn't resolve it. For a playlist, try the page's og:title (public "PL…" ones and
            // some others expose the real name there even when oEmbed 404s); videos have no such gap.
            guard kind == .playlist, let pageURL = URL(string: target) else { completion(nil); return }
            fetchPageOgTitle(from: pageURL, completion: completion)
        }
    }

    // MARK: -

    /// Best-effort title from a YouTube page's Open Graph meta. YouTube serves the og:title in the
    /// initial HTML for playlist pages; if the request instead hits a consent/bot interstitial the tag
    /// is absent and we return nil (caller keeps its placeholder). Never throws — purely additive.
    private static func fetchPageOgTitle(from url: URL, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.httpMethod = "GET"
        // A desktop UA + en/US hints get the server-rendered HTML with the og:title meta.
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            var title: String?
            if let data = data, let html = String(data: data, encoding: .utf8) {
                title = ogTitle(in: html)
            }
            let cleaned = title?.trimmingCharacters(in: .whitespacesAndNewlines)
            // Ignore the generic site title YouTube falls back to when the playlist isn't resolvable.
            let isGeneric = cleaned == nil || cleaned == "YouTube" || cleaned == "YouTube Music"
            DispatchQueue.main.async { completion(isGeneric ? nil : cleaned) }
        }.resume()
    }

    /// Extract the `<meta property="og:title" content="…">` value from raw HTML (HTML-entity decoded).
    private static func ogTitle(in html: String) -> String? {
        guard let metaRange = html.range(of: "<meta property=\"og:title\"") else { return nil }
        let rest = html[metaRange.upperBound...]
        guard let contentStart = rest.range(of: "content=\"") else { return nil }
        let afterContent = rest[contentStart.upperBound...]
        guard let contentEnd = afterContent.range(of: "\"") else { return nil }
        return decodeHTMLEntities(String(afterContent[..<contentEnd.lowerBound]))
    }

    private static func decodeHTMLEntities(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

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
