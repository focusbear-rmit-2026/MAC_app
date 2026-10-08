import Cocoa

struct ManagedBrowserObservation {
    let url: String
    let title: String?
    let windowId: Int
    let tabId: Int
    var processId: pid_t? = nil
}

enum ManagedBrowserAccess {
    static func observe(_ browser: BROWSER) -> ManagedBrowserObservation? {
        if browser == ._GOOGLE_CHROME_ {
            guard let front = NSWorkspace.shared.frontmostApplication,
                  ChromeProcessTabs.applications().contains(where: { $0.processIdentifier == front.processIdentifier }) else { return nil }
            return observeChrome(pid: front.processIdentifier)
        }
        if browser == ._FIREFOX_ { return firefoxServer.managedObservation }
        guard browser != ._SIGMA_OS_, let name = getCurrentBrowserNameFrom(browser: browser) else { return nil }
        let tab = browser == ._SAFARI_ ? "current tab" : "active tab"
        let tabIdentifier = browser == ._SAFARI_ ? "index" : "id"
        let title = browser == ._SAFARI_ ? "name" : "title"
        guard let result = runBrowserAppleScript("""
        tell application "\(name)"
            if (count of windows) = 0 then return {}
            set observedWindow to front window
            set observedTab to \(tab) of observedWindow
            return {URL of observedTab, \(title) of observedTab, id of observedWindow, \(tabIdentifier) of observedTab}
        end tell
        """, logErrors: false), result.numberOfItems == 4, let url = result.atIndex(1)?.stringValue,
              let window = result.atIndex(3), let tabId = result.atIndex(4) else { return nil }
        return ManagedBrowserObservation(url: url, title: result.atIndex(2)?.stringValue,
            windowId: Int(window.int32Value), tabId: Int(tabId.int32Value))
    }

    static func chromeObservation(pid: pid_t, read: (NSAppleEventDescriptor) throws -> NSAppleEventDescriptor) throws -> ManagedBrowserObservation? {
        typealias AE = ChromeProcessTabs
        let front = AE.object("cwin", form: "indx", key: .init(int32: 1))
        let id = try read(AE.property("ID  ", of: front))
        let window = AE.object("cwin", form: "ID  ", key: id)
        let tab = AE.property("acTa", of: window)
        let properties = try read(AE.property("pALL", of: tab))
        guard let tabId = properties.forKeyword(AE.code("ID  ")),
              let url = properties.forKeyword(AE.code("URL "))?.stringValue,
              try read(AE.property("ID  ", of: front)).int32Value == id.int32Value,
              try read(AE.property("ID  ", of: tab)).int32Value == tabId.int32Value else { return nil }
        return ManagedBrowserObservation(url: url, title: properties.forKeyword(AE.code("pnam"))?.stringValue,
            windowId: Int(id.int32Value), tabId: Int(tabId.int32Value), processId: pid)
    }

    private static func observeChrome(pid: pid_t) -> ManagedBrowserObservation? {
        try? chromeObservation(pid: pid) { try ChromeProcessTabs.send(pid: pid, object: $0) }
    }

    /// Recovery access is deliberately bounded to first-party authentication/help, not arbitrary policy exceptions.
    private static let essentialHosts = Set(["app.focusbear.io", "dashboard.focusbear.io", "help.focusbear.io",
        "api.focusbear.io", "dev-2hidr8ad.us.auth0.com"])

    static func isEssential(_ resource: ManagedResource) -> Bool {
        essentialHosts.contains(resource.host) && resource.port == nil && resource.normalizedURL.hasPrefix("https://")
    }

    @discardableResult
    static func navigate(_ browser: BROWSER, to url: String, expectedURL: String, target: ManagedBrowserObservation,
                         authorization: @escaping () -> Bool = { true }) -> Bool {
        guard authorization() else { return false }
        if browser == ._GOOGLE_CHROME_ {
            guard let pid = target.processId,
                  ChromeProcessTabs.applications().contains(where: { $0.processIdentifier == pid }),
                  let current = observeChrome(pid: pid), current.windowId == target.windowId,
                  current.tabId == target.tabId, current.url == expectedURL, authorization() else { return false }
            typealias AE = ChromeProcessTabs
            let window = AE.object("cwin", form: "ID  ", key: .init(int32: Int32(target.windowId)))
            let tab = AE.object("CrTb", form: "ID  ", key: .init(int32: Int32(target.tabId)), container: window)
            let event = NSAppleEventDescriptor(eventClass: AE.code("core"), eventID: AE.code("setd"),
                targetDescriptor: .init(processIdentifier: pid), returnID: -1, transactionID: 0)
            event.setParam(AE.property("URL ", of: tab), forKeyword: AE.code("----"))
            event.setParam(.init(string: url), forKeyword: AE.code("data"))
            do {
                guard authorization() else { return false }
                let reply = try event.sendEvent(options: [.waitForReply, .neverInteract], timeout: 1)
                return (reply.paramDescriptor(forKeyword: AE.code("errn"))?.int32Value ?? 0) == 0
            } catch { return false }
        }
        if browser == ._FIREFOX_ {
            return firefoxServer.sendManagedNavigation(url: url, expectedURL: expectedURL, target: target, authorization: authorization)
        }
        let escaped = url.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")
        guard browser != ._SIGMA_OS_ else { return false }
        guard let name = getCurrentBrowserNameFrom(browser: browser) else { return false }
        let tab = browser == ._SAFARI_ ? "current tab" : "active tab"
        let expected = expectedURL.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")
        var condition = "URL of targetTab is \"\(expected)\""
        do {
            let identifier = browser == ._SAFARI_ ? "index" : "id"
            condition += " and id of targetWindow is \(target.windowId) and \(identifier) of targetTab is \(target.tabId)"
        }
        let result = runBrowserAppleScript("""
        tell application "\(name)"
            if (count of windows) > 0 then
                set targetWindow to front window
                set targetTab to \(tab) of targetWindow
                if \(condition) then
                    set URL of targetTab to "\(escaped)"
                    return true
                end if
            end if
            return false
        end tell
        """, authorization: authorization, logErrors: false)
        return result?.booleanValue == true
    }
}

struct ManagedEnforcementBinding {
    var snapshotId: String?
    var session: UUID
    var policyId: String?
    var revision: Int?
    var recovery: Bool
}

/// A value snapshot avoids main-thread waits from existing browser/AppleScript queues.
final class ManagedNavigationGate {
    private let lock = NSLock()
    private var snapshot: ManagedPolicySnapshot?
    private var isManaged = false
    private var session = UUID()

    var hasManagedIdentity: Bool {
        lock.lock(); defer { lock.unlock() }; return isManaged
    }
    private var isRecovery = false
    private var denied = Set<String>()
    private var serverDate = Date()
    private var uptime: TimeInterval = 0

    func update(snapshot: ManagedPolicySnapshot?, managed: Bool, session: UUID, recovery: Bool, denied: Set<String>, now: Date) {
        lock.lock(); defer { lock.unlock() }
        self.snapshot = snapshot; self.session = session; isManaged = managed; isRecovery = recovery
        self.denied = denied; serverDate = now; uptime = ProcessInfo.processInfo.systemUptime
    }

    func denies(_ resource: ManagedResource) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard isManaged else { return false }
        let now = serverDate.addingTimeInterval(max(0, ProcessInfo.processInfo.systemUptime - uptime))
        guard !isRecovery, let snapshot = snapshot, ManagedPolicyLease.isUsable(snapshot, clockStatus: "trusted", at: now) else {
            return !ManagedBrowserAccess.isEssential(resource)
        }
        guard let policy = snapshot.activePolicy(at: now) else { return false }
        return denied.contains(policy.id + ":" + String(policy.revision) + ":" + resource.hash)
    }

    func deniesMalformedWebsite(_ value: String) -> Bool {
        guard value.lowercased().hasPrefix("https://") || value.lowercased().hasPrefix("http://") else { return false }
        lock.lock(); defer { lock.unlock() }
        guard isManaged else { return false }
        if isRecovery { return true }
        let now = serverDate.addingTimeInterval(max(0, ProcessInfo.processInfo.systemUptime - uptime))
        guard let snapshot = snapshot, ManagedPolicyLease.isUsable(snapshot, clockStatus: "trusted", at: now) else { return true }
        guard let policy = snapshot.activePolicy(at: now) else { return false }
        return !policy.blockedCategories.isEmpty && (policy.unavailableAction != "allow" || policy.blockedCategories.contains("not_resolved"))
    }

    func permitsRevisit(_ binding: ManagedEnforcementBinding) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard session == binding.session, snapshot?.snapshotId == binding.snapshotId, !isRecovery else { return false }
        let now = serverDate.addingTimeInterval(max(0, ProcessInfo.processInfo.systemUptime - uptime))
        guard let snapshot = snapshot, ManagedPolicyLease.isUsable(snapshot, clockStatus: "trusted", at: now) else { return false }
        let policy = snapshot.activePolicy(at: now)
        return policy?.id == binding.policyId && policy?.revision == binding.revision
    }

    func permits(_ binding: ManagedEnforcementBinding) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard isManaged, session == binding.session, snapshot?.snapshotId == binding.snapshotId else { return false }
        let now = serverDate.addingTimeInterval(max(0, ProcessInfo.processInfo.systemUptime - uptime))
        if binding.recovery { return isRecovery || snapshot.map { !ManagedPolicyLease.isUsable($0, clockStatus: "trusted", at: now) } ?? true }
        guard !isRecovery, let snapshot = snapshot, ManagedPolicyLease.isUsable(snapshot, clockStatus: "trusted", at: now),
              let policy = snapshot.activePolicy(at: now) else { return false }
        return policy.id == binding.policyId && policy.revision == binding.revision
    }
}

enum ManagedIdentityRules {
    static func requiresManagedDeviceRecovery(isSupervised: Bool, currentUser: String, newUser: String, currentDevice: String, newDevice: String) -> Bool {
        isSupervised && currentUser == newUser && currentDevice != newDevice
    }

    static func permitsSwitch(isSupervised: Bool, currentUser: String, newUser: String) -> Bool {
        !isSupervised || currentUser.isEmpty || currentUser == newUser
    }
}
