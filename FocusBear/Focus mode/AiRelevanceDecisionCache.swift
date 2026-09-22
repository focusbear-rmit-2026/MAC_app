import Foundation

/// Exact classifier inputs, separate from alignment-score history and time-limited appeals.
/// Never normalizes URLs to domains: query, fragment, title and app window context can change meaning.
struct AiRelevanceDecisionKey: Hashable {
    let context: Data
    let kind: String
    let target: String
    let content: [String]

    /// The key's title is stored lowercased (the caller lowercases it for the relevance payload) while
    /// a live re-read returns the browser's original casing, so an exact comparison was false for any
    /// page with a capital in its title — i.e. nearly all of them. That silently discarded almost
    /// every verdict: on a real session, 17 of 20 checks ran, answered, and were thrown away here.
    /// Host casing is likewise not meaningful, so both sides are normalised before comparing.
    func matchesURLObservation(url: String?, title: String?, bundleIdentifier: String?) -> Bool {
        guard kind == "url", content.count >= 3 else { return false }
        let sameURL = url?.lowercased() == target.lowercased()
        let sameTitle = title?.lowercased() == content[1].lowercased()
        return sameURL && sameTitle && bundleIdentifier == content[2]
    }

    static func isCacheable(probability: Double?, reason: String) -> Bool {
        guard let probability = probability, probability.isFinite, (0...1).contains(probability) else { return false }
        // The legacy endpoint can return this fallback in a successful HTTP response.
        return reason.lowercased() != "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"
    }

    static func activeTaskIdentity(in queue: String, popupTask: String) -> String {
        if !popupTask.isEmpty { return "popup:" + popupTask }
        guard let data = queue.data(using: .utf8),
              let tasks = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let active = tasks.first(where: { $0["isPlaying"] as? Bool == true }) else { return "" }
        // Include the ID even when two tasks have identical titles.
        let fields = [active["id"] as? String ?? "", active["title"] as? String ?? "",
                      active["details"] as? String ?? ""]
        return String(data: (try? JSONSerialization.data(withJSONObject: fields)) ?? Data(), encoding: .utf8) ?? ""
    }
}

/// Session memory only. Bounded LRU storage; errors/timeouts are never decisions and must not be cached.
/// The caller verifies the current account, task and navigation before storing or applying a response.
final class AiRelevanceDecisionCache<Value> {
    private let capacity: Int
    private let lock = NSLock()
    private var values: [AiRelevanceDecisionKey: Value] = [:]
    private var order: [AiRelevanceDecisionKey] = []
    private var epoch: UInt64 = 0

    var generation: UInt64 {
        lock.lock(); defer { lock.unlock() }
        return epoch
    }

    init(capacity: Int = 256) { self.capacity = max(1, capacity) }

    func value(for key: AiRelevanceDecisionKey) -> Value? {
        lock.lock(); defer { lock.unlock() }
        guard let value = values[key] else { return nil }
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }

    func store(_ value: Value, for key: AiRelevanceDecisionKey) {
        lock.lock(); defer { lock.unlock() }
        values[key] = value
        order.removeAll { $0 == key }
        order.append(key)
        while order.count > capacity { values.removeValue(forKey: order.removeFirst()) }
    }

    /// Both cached and fresh decisions must still belong to the currently observed input.
    /// A late response after navigation or task changes is neither stored nor delivered.
    func resolve(for key: AiRelevanceDecisionKey,
                 isCurrent: @escaping () -> Bool,
                 shouldCache: @escaping (Value) -> Bool,
                 load: (@escaping (Value) -> Void) -> Void,
                 completion: @escaping (Value) -> Void) {
        let requestedGeneration = generation
        if let cached = value(for: key) {
            if isCurrent() { completion(cached) }
            return
        }
        load { [weak self] value in
            guard let self = self, self.generation == requestedGeneration, isCurrent() else { return }
            if shouldCache(value) { self.store(value, for: key) }
            completion(value)
        }
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        epoch &+= 1
        values.removeAll()
        order.removeAll()
    }
}

/// Add the resource check at the AppleScript mutation itself, after the browser queue wait.
/// Firefox uses its separate extension protocol (not AppleScript), so its payload is left intact.
enum AiRelevanceRedirectGuard {
    static func script(_ script: String, expectedURL: String) -> String {
        let targets = [("set URL of active_tab to", "URL of active_tab"),
                       ("set URL of active tab in front window to", "URL of active tab in front window"),
                       ("set value to", "value of urlField")]
        guard let target = targets.first(where: { script.contains($0.0) }) else { return script }
        guard !expectedURL.isEmpty,
              !expectedURL.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return "return" }
        let escaped = expectedURL.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let condition = "considering case\nif (\(target.1) as text) is not equal to \"\(escaped)\" then return\nend considering\n"
        return script.replacingOccurrences(of: target.0, with: condition + target.0)
    }
}
