import Foundation
import CryptoKit
import Darwin

enum ManagedPolicyLease {
    static func isUsable(_ snapshot: ManagedPolicySnapshot, clockStatus: String, at date: Date) -> Bool {
        guard clockStatus == "trusted", snapshot.schemaVersion == 1,
              let id = snapshot.snapshotId, id.count == 64,
              id.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
              let server = snapshot.serverTime.flatMap(ManagedDate.parse),
              let expiry = snapshot.offlineValidUntil.flatMap(ManagedDate.parse),
              server <= date.addingTimeInterval(60), expiry > server, date < expiry else { return false }
        return true
    }
}

enum ManagedPolicyEvaluator {
    static let taxonomyVersion = "2026-09-08"

    static func isActive(_ policy: ManagedPolicy, at date: Date) -> Bool {
        guard policy.isEnabled, let zone = TimeZone(identifier: policy.timeZone) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let today = dayKey(date, calendar: calendar)
        guard !isExcluded(today, policy: policy) else { return false }
        // An overnight window belongs to the day it STARTED on, hence the previous day's code.
        let weekday = calendar.component(.weekday, from: date) - 1
        let todayCode = ManagedDay.code(at: weekday)
        let yesterdayCode = ManagedDay.code(at: weekday - 1)
        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let previous = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        return policy.windows.contains { window in
            if window.allDay == true { return window.daysOfWeek.contains(todayCode) }
            guard let start = minuteOfDay(window.startTime), let end = minuteOfDay(window.endTime), start != end else { return false }
            if start < end { return window.daysOfWeek.contains(todayCode) && minute >= start && minute < end }
            return (window.daysOfWeek.contains(todayCode) && minute >= start) ||
                (window.daysOfWeek.contains(yesterdayCode) && minute < end &&
                 !isExcluded(dayKey(previous, calendar: calendar), policy: policy))
        }
    }

    static func matchesAllowlist(_ policy: ManagedPolicy, url: String, at date: Date) -> Bool {
        guard let resource = ManagedResource(url) else { return false }
        return policy.allowlist.contains { entry in
            if let expiry = entry.expiresAt {
                guard let instant = ManagedDate.parse(expiry), instant > date else { return false }
            }
            guard let allowed = ManagedResource(entry.url), allowed.port == resource.port else { return false }
            let hostMatches = resource.host == allowed.host ||
                (entry.includeSubdomains && resource.host.hasSuffix("." + allowed.host))
            let path = allowed.path.hasSuffix("/") ? String(allowed.path.dropLast()) : allowed.path
            return hostMatches && (path.isEmpty || resource.path == path || resource.path.hasPrefix(path + "/"))
        }
    }

    static func offlineDecision(_ policy: ManagedPolicy, url: String, at date: Date,
                                categories: [String] = [], status: String = "unavailable") -> (allowed: Bool, reason: String, categories: [String]) {
        if !isActive(policy, at: date) { return (true, "inactive", []) }
        if matchesAllowlist(policy, url: url, at: date) { return (true, "policy_allowlist", []) }
        if policy.blockedCategories.isEmpty { return (true, "no_blocked_categories", []) }
        let synthetic = status == "unknown" ? ["unknown"] : (["unavailable", "not_resolved"].contains(status) ? ["not_resolved"] : [])
        let matched = Array(Set(categories + synthetic)).filter(policy.blockedCategories.contains).sorted()
        if !matched.isEmpty { return (false, "blocked_category", matched) }
        if status == "classified" { return (true, "categories_allowed", []) }
        if status == "unknown" { return (policy.unknownAction == "allow", "classification_unknown", []) }
        return (policy.unavailableAction == "allow", "classification_unavailable", [])
    }

    static func cachedDecision(_ classification: ManagedClassification, policy: ManagedPolicy, resource: ManagedResource,
                               at date: Date) -> (allowed: Bool, reason: String, categories: [String])? {
        guard classification.taxonomyVersion == taxonomyVersion,
              let expiry = ManagedDate.parse(classification.expiresAt), expiry > date else { return nil }
        let complete = Set(policy.blockedCategories).isSubset(of: Set(classification.evaluatedCategories ?? []))
        // Positive safety signals remain binding even when another requested category has no coverage.
        return offlineDecision(policy, url: resource.normalizedURL, at: date, categories: classification.categories,
            status: complete ? classification.classificationStatus : "unavailable")
    }

    private static func minuteOfDay(_ value: String) -> Int? {
        let parts = value.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return hour * 60 + minute
    }

    private static func isExcluded(_ day: String, policy: ManagedPolicy) -> Bool {
        policy.excludedDates.contains { day >= $0.startDate && day <= $0.endDate }
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let values = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", values.year ?? 0, values.month ?? 0, values.day ?? 0)
    }
}

struct ManagedResource: Equatable {
    let normalizedURL: String
    let host: String
    let path: String
    let port: Int?
    var hash: String { Self.hash(normalizedURL) }

    init?(_ raw: String) {
        guard raw.count <= 4096, !raw.unicodeScalars.contains(where: { $0.value <= 32 || $0.value == 127 }),
              !raw.contains("\\") else { return nil }
        let input = raw.contains("://") ? raw : "https://" + raw
        let pathBeforeQuery = input.components(separatedBy: "?")[0].components(separatedBy: "#")[0]
        guard pathBeforeQuery.range(of: "%([^0-9a-fA-F]|[0-9a-fA-F]([^0-9a-fA-F]|$)|$)", options: .regularExpression) == nil else { return nil }
        guard var components = URLComponents(string: input),
              let scheme = components.scheme?.lowercased(), ["https", "http"].contains(scheme),
              components.user == nil, components.password == nil,
              let resolvedHost = components.url?.host?.lowercased(), !resolvedHost.isEmpty else { return nil }
        var host = resolvedHost
        if host.hasSuffix(".") { host.removeLast() }
        guard !host.isEmpty else { return nil }
        guard let canonicalHost = Self.canonicalHost(host) else { return nil }
        host = canonicalHost
        components.scheme = scheme
        components.host = host
        components.fragment = nil
        if (scheme == "https" && components.port == 443) || (scheme == "http" && components.port == 80) { components.port = nil }
        guard let path = Self.normalizePath(components.percentEncodedPath) else { return nil }
        components.percentEncodedPath = path
        if components.percentEncodedQuery == "" { components.percentEncodedQuery = nil }
        guard let normalized = components.url?.absoluteString else { return nil }
        self.normalizedURL = normalized
        self.host = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        self.path = path
        self.port = components.port
    }

    static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func canonicalHost(_ host: String) -> String? {
        if host.contains(":") {
            let bare = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            var address = in6_addr()
            guard inet_pton(AF_INET6, bare, &address) == 1 else { return nil }
            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            guard inet_ntop(AF_INET6, &address, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil else { return nil }
            return "[" + String(cString: buffer) + "]"
        }
        let parts = host.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard let last = parts.last else { return nil }
        guard last.allSatisfy(\.isNumber) || last.lowercased().hasPrefix("0x") else { return host }
        guard (1...4).contains(parts.count) else { return nil }
        let numbers = parts.compactMap { part -> UInt64? in
            if part.lowercased().hasPrefix("0x") { return UInt64(part.dropFirst(2), radix: 16) }
            if part.count > 1 && part.hasPrefix("0") { return UInt64(part.dropFirst(), radix: 8) }
            return UInt64(part)
        }
        guard numbers.count == parts.count, numbers.dropLast().allSatisfy({ $0 <= 255 }),
              let tail = numbers.last, tail < (UInt64(1) << (8 * (5 - numbers.count))) else { return nil }
        var value = tail
        for (index, byte) in numbers.dropLast().enumerated() { value += byte << (8 * (3 - index)) }
        return [24, 16, 8, 0].map { String((value >> $0) & 255) }.joined(separator: ".")
    }

    private static func normalizePath(_ raw: String) -> String? {
        let bytes = Array(raw.utf8)
        var index = 0
        var escaped = ""
        let unreserved = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        while index < bytes.count {
            if bytes[index] == 37 {
                guard index + 2 < bytes.count, let value = UInt8(String(bytes: bytes[(index + 1)...(index + 2)], encoding: .utf8) ?? "", radix: 16) else { return nil }
                let scalar = UnicodeScalar(Int(value))!
                escaped += unreserved.contains(scalar) ? String(scalar) : String(format: "%%%02X", value)
                index += 3
            } else {
                escaped += String(UnicodeScalar(Int(bytes[index]))!)
                index += 1
            }
        }
        var segments: [String] = []
        let parts = escaped.split(separator: "/", omittingEmptySubsequences: false)
        for (position, part) in parts.enumerated() {
            if position == 0 && part.isEmpty { continue }
            if part == ".." { if !segments.isEmpty { segments.removeLast() } }
            else if part != "." { segments.append(String(part)) }
        }
        let needsTrailingSlash = escaped.hasSuffix("/.") || escaped.hasSuffix("/..")
        var normalized = "/" + segments.joined(separator: "/")
        if needsTrailingSlash && !normalized.hasSuffix("/") { normalized += "/" }
        return normalized
    }
}
