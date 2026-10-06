//
//  LogRedactor.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import CryptoKit
import Foundation

/// Removes secrets from a log line before it reaches the plaintext log file.
///
/// The log is readable by any process running as the user, is attached to support reports and is
/// read by agents, so it never holds tokens, passwords, signed-URL credentials or email addresses.
/// Emails become a short stable hash so two lines about the same account can still be matched.
///
/// Secrets have a shape this can recognise in any line. The user's own content (to-do and habit
/// names, focus goals, notes, the stores `SecureStore` seals, and the pages and window titles they
/// look at) has none, so it is kept out where it is logged, with `LogPrivacy`; the full URLs and
/// titles live only in the 30-minute `BrowsingHistory`. `scripts/scan-logs-for-sensitive-data.py`
/// checks both on real logs.
enum LogRedactor {
    static let redactedValue = "<redacted>"
    static let redactedJWT = "<jwt>"

    /// Values that only say whether something is set, e.g. `hasPassword: true`. Not secret, and
    /// redacting them would make password-gate settings unreadable in the log.
    private static let flagValues: Set<String> = ["true", "false", "0", "1", "yes", "no", "nil", "null", "<null>"]

    private static let jwt = regex(#"eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]*"#)
    private static let bearer = regex(#"(?i)\b(bearer)\s+[A-Za-z0-9\-._~+/]+=*"#)
    /// `"access_token": "…"`, `accessToken = …;`, `email_token=…` (JSON, NSDictionary descriptions,
    /// URL queries): any field named `token` or ending in `_token` / `Token`.
    private static let tokenField = regex(#"(\b(?:[A-Za-z_]*_(?:token|TOKEN)|[a-z][A-Za-z]*Token|[Tt]oken)"?\s*[:=]\s*)("(?:[^"\\]|\\.)*"|[^\s,;&}\)]+)"#)
    /// Query parameters that carry a credential without saying "token": OAuth codes, signed-URL
    /// signatures and credentials (S3 `X-Amz-*`), session ids, API keys.
    private static let secretQueryParameter = regex(#"(?i)([?&;](?:code|sig|signature|x-amz-signature|x-amz-credential|x-amz-security-token|session_?id|api_?key|key|secret|auth)=)([^&\s"'#<]+)"#)
    /// Any key that ends in "password" (`password`, `kAppPassword`, `new_password`). Keys that merely
    /// contain it, like `PasswordRequireInQuit`, are not matched.
    private static let passwordField = regex(#"(?i)(\b[a-z_]*password"?\s*[:=]\s*)("(?:[^"\\]|\\.)*"|[^\s,;}\)]+)"#)
    private static let email = regex(#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#)

    static func redact(_ line: String) -> String {
        var result = line
        if result.contains("eyJ") {
            result = replaceMatches(of: jwt, in: result) { _ in redactedJWT }
        }
        if result.range(of: "bearer", options: .caseInsensitive) != nil {
            result = replaceMatches(of: bearer, in: result) { match in "\(match[1]) \(redactedValue)" }
        }
        if result.range(of: "token", options: .caseInsensitive) != nil {
            result = replaceMatches(of: tokenField, in: result, replacement: redactUnlessFlag)
        }
        if result.contains("=") {
            result = replaceMatches(of: secretQueryParameter, in: result) { match in match[1] + redactedValue }
        }
        if result.range(of: "password", options: .caseInsensitive) != nil {
            result = replaceMatches(of: passwordField, in: result, replacement: redactUnlessFlag)
        }
        if result.contains("@") {
            result = replaceMatches(of: email, in: result) { match in "<email:\(LogPrivacy.shortHash(match[0].lowercased()))>" }
        }
        return result
    }

    /// `hasPassword: true` and `hasToken = 0;` say whether something is set; only real values go.
    private static func redactUnlessFlag(_ match: [String]) -> String {
        let value = match[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        guard !flagValues.contains(value.lowercased()) else { return match[0] }
        return match[1] + redactedValue
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are literals; failing to compile one is a programming error.
        try! NSRegularExpression(pattern: pattern)
    }

    /// Replaces each match, passing the replacement the whole match followed by its capture groups.
    private static func replaceMatches(of expression: NSRegularExpression,
                                       in text: String,
                                       replacement: ([String]) -> String) -> String {
        let nsText = text as NSString
        let matches = expression.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }
        let result = NSMutableString(string: text)
        for match in matches.reversed() {
            let groups = (0..<match.numberOfRanges).map { index -> String in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : nsText.substring(with: range)
            }
            result.replaceCharacters(in: match.range, with: replacement(groups))
        }
        return result as String
    }
}

/// Describes the user's own content in a log line without writing it: to-do, habit and schedule
/// names, focus goals, free-text reasons, and the payloads of stores `SecureStore` seals at rest.
///
/// A log line that copied those would undo the encryption: the log is plaintext, readable by any
/// process running as the user, and travels with support reports. The descriptions keep what a
/// reader debugging the app needs (whether something was set, its size, a short hash that tells two
/// values apart across lines) and nothing the user wrote.
enum LogPrivacy {
    static let noValue = "<none>"
    static let hashLength = 4
    /// Query values that are never the user's words: numbers, booleans and ISO dates.
    private static let readableQueryValue = try! NSRegularExpression(
        pattern: #"^(?:-?[0-9]+(?:\.[0-9]+)?|true|false|[0-9]{4}-[0-9]{2}-[0-9]{2}(?:[T ][0-9:.]+Z?)?)$"#)
    /// SCREAMING_CASE values stay readable only under these names (`status=NOT_STARTED`,
    /// `sort_mode=SMART`): an all-caps event title such as `OOO` is still the user's text.
    private static let enumQueryParameters: Set<String> = ["status", "order", "sort", "sort_mode", "type", "mode"]
    private static let screamingCaseValue = try! NSRegularExpression(pattern: #"^[A-Z][A-Z0-9_]*$"#)

    /// `<text:1a2b:len14>`, or `<none>` for nil or empty. No spaces, commas, pipes or ampersands, so
    /// it stays one token inside a URL query or a Focus Button protocol line.
    static func text(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return noValue }
        return "<text:\(shortHash(value)):len\(value.count)>"
    }

    /// The shape of a payload, never its values: `<dictionary keys=a,b,c>`, `<array count=3>`.
    static func structure(_ value: Any?) -> String {
        guard let value else { return noValue }
        switch value {
        case let dictionary as [AnyHashable: Any]:
            return "<dictionary keys=\(dictionary.keys.map { "\($0)" }.sorted().joined(separator: ","))>"
        case let array as [Any]:
            return "<array count=\(array.count)>"
        case let string as String:
            return text(string)
        case let data as Data:
            return "<\(data.count) bytes>"
        default:
            return "<\(type(of: value))>"
        }
    }

    /// A request path, URL or deep link with each query value that could be the user's text described
    /// instead of written. Everything before the query, and readable values, are kept.
    static func url(_ value: String) -> String {
        guard let queryStart = value.firstIndex(of: "?") else { return value }
        let base = value[..<queryStart]
        var query = value[value.index(after: queryStart)...]
        var fragment = ""
        if let fragmentStart = query.firstIndex(of: "#") {
            let fragmentText = String(query[query.index(after: fragmentStart)...])
            fragment = "#" + (isDescription(fragmentText) ? fragmentText : text(fragmentText))
            query = query[..<fragmentStart]
        }
        let parameters = query.split(separator: "&", omittingEmptySubsequences: false).map(describeQueryParameter)
        return String(base) + "?" + parameters.joined(separator: "&") + fragment
    }

    private static func describeQueryParameter(_ parameter: Substring) -> String {
        // A bare component is either a flag or the tail of a value that held "&" after decoding.
        guard let equals = parameter.firstIndex(of: "=") else {
            return isReadableQueryValue(String(parameter)) ? String(parameter) : text(String(parameter))
        }
        let name = parameter[..<equals]
        let rawValue = String(parameter[parameter.index(after: equals)...])
        let value = rawValue.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? rawValue
        let isReadable = isReadableQueryValue(value)
            || (enumQueryParameters.contains(name.lowercased()) && matches(screamingCaseValue, value))
        return "\(name)=\(isReadable ? rawValue : text(value))"
    }

    private static func isReadableQueryValue(_ value: String) -> Bool {
        value.isEmpty || isDescription(value) || matches(readableQueryValue, value)
    }

    private static func matches(_ expression: NSRegularExpression, _ value: String) -> Bool {
        expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil
    }

    /// A page the user looked at, as its site and a short hash of the whole URL:
    /// `<site:docs.example.org:1a2b>`. The hash tells two pages on one site apart across lines and is
    /// the `ref=` of the matching `BrowsingHistory` entry, which holds the full URL for 30 minutes.
    /// A URL with no host (`file:///…`, `about:blank`) is named by its scheme; anything that is not a
    /// URL at all is described as text.
    static func site(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return noValue }
        if isDescription(value) { return value }
        guard let site = siteName(of: value) else { return text(value) }
        return "<site:\(site):\(shortHash(value))>"
    }

    /// `scheme://host…` or a bare `host/path…` (the blocker logs URLs without their scheme). A bare
    /// single label only counts with a port (`localhost:3000`), or every app name would be a "site".
    /// Focus Bear's own services: requests the app makes (API calls, the config file, updates), never
    /// pages the user browsed, so their URLs stay whole in the log.
    static let appOwnedHosts: Set<String> = ["api.focusbear.io", "downloads.focusbear.io", "focus-bear.github.io"]

    static func isAppOwned(_ url: String) -> Bool {
        siteName(of: url).map(appOwnedHosts.contains) ?? false
    }

    private static let scheme = try! NSRegularExpression(pattern: #"^([A-Za-z][A-Za-z0-9+.-]*):"#)
    private static let bareHost = try! NSRegularExpression(
        pattern: #"^([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+|[A-Za-z0-9-]+(?=:[0-9]))(?::[0-9]+)?(?:[/?#]|$)"#)

    private static func siteName(of value: String) -> String? {
        if let host = firstGroup(of: bareHost, in: value) { return host.lowercased() }
        guard let scheme = firstGroup(of: scheme, in: value) else { return nil }
        // URLComponents refuses a URL with an unencoded space, which browsers still report.
        let parsable = value.replacingOccurrences(of: " ", with: "%20")
        let host = URLComponents(string: parsable)?.host ?? ""
        return (host.isEmpty ? scheme : host).lowercased()
    }

    private static func firstGroup(of expression: NSRegularExpression, in value: String) -> String? {
        guard let match = expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let range = Range(match.range(at: 1), in: value) else { return nil }
        return String(value[range])
    }

    /// Already a description (`<text:1a2b:len5>`, `<redacted>`), so describing it again would only
    /// hash the description: rewriting an old log twice must change nothing the second time.
    static func isDescription(_ value: String) -> Bool {
        value.hasPrefix("<") && value.hasSuffix(">")
    }

    static func shortHash(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(hashLength))
    }
}
