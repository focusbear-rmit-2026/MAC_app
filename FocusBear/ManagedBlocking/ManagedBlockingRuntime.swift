import Cocoa
import Combine

enum ManagedSyncState: String { case loading, online, offline, recovery, unmanaged }

/// Managed enforcement has its own lifecycle. Personal timers, breaks and teacher unlocks cannot stop it.
final class ManagedBlockingRuntime: ObservableObject {
    static let shared = ManagedBlockingRuntime()
    @Published private(set) var effectivePolicy: ManagedPolicySnapshot?
    @Published private(set) var activePolicy: ManagedPolicy?
    @Published private(set) var isSettingsLocked = false
    @Published private(set) var syncState = ManagedSyncState.loading
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var queuedViolationCount = 0
    @Published private(set) var rejectedViolationCount = 0
    @Published private(set) var lastError: String?
    @Published private(set) var currentRequest: ManagedSettingsRequest?
    @Published private(set) var isRequestBusy = false
    @Published private(set) var clockStatus = "uncertain"
    @Published private(set) var permissionStatus = "unknown"
    private let store = ManagedPolicyStore()
    private let api = ManagedBlockingAPI.shared
    private let browserQueue = DispatchQueue(label: "io.focusbear.managed-browser", qos: .utility)
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var state: ManagedStoredState?
    private var userId = ""
    private var deviceId = ""
    private var serverAnchor = Date()
    private var wallAnchor = Date()
    private var uptimeAnchor = ProcessInfo.processInfo.systemUptime
    private var lastRefresh: TimeInterval = -.infinity
    private var lastFlush: TimeInterval = -.infinity
    private var isRefreshing = false
    private var isCheckingBrowser = false
    private var isUploading = false
    private var sessionGeneration = UUID()
    private var snapshotRequestId = UUID()
    private var lastObservation: String?
    private var eventId = UUID().uuidString
    private var cachedClassifications: [String: ManagedClassification] = [:]
    private var lastReceipt: TimeInterval = -.infinity
    private var isStorageHealthy = true
    private var reportedEvents = Set<String>()
    private var deniedResources = Set<String>()
    private var appealedResources = Set<String>()
    private var failedBrowserIds = Set<Int>()
    private let navigationGate = ManagedNavigationGate()
    /// A UI test installed the policy (`installForUITests`): there is no stored session to restore or
    /// replace, and no identity, so nothing here can reach the keychain or the server.
    private var isUITestFixture = false

    var sessionToken: UUID { sessionGeneration }
    var hasManagedIdentity: Bool { navigationGate.hasManagedIdentity }
    private var apiIdentity: ManagedAPIIdentity { ManagedAPIIdentity(userId: userId, deviceId: deviceId) }

    var effectiveNow: Date { serverAnchor.addingTimeInterval(max(0, ProcessInfo.processInfo.systemUptime - uptimeAnchor)) }
    var canProposeHomeChanges: Bool {
        guard syncState == .online, clockStatus == "trusted", let home = effectivePolicy?.home,
              let request = currentRequest, appdelegate?.user?.userId == userId,
              currentDeviceId == deviceId else { return false }
        return request.policyId == home.id && request.permitsProposal(deviceId: deviceId, revision: home.revision, at: effectiveNow)
    }

    func restoreLastSession() {
        #if DEBUG
        if let fixture = UITestManagedSafetyFixture.requestedPolicy { return installForUITests(fixture) }
        #endif
        startTimer()
        // Keychain access can block while macOS is recovering the login keychain. Do not hold AppKit
        // startup hostage to the optional managed-session restore; the routine UI and its ordinary
        // timers can start first. (A signature mismatch no longer waits on a password sheet — see
        // ManagedKeychain — but the lookup itself is still not guaranteed to be quick.)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self, self.userId.isEmpty, let identity = self.store.lastIdentity else { return }
            DispatchQueue.main.async {
                guard self.userId.isEmpty else { return }
                self.loadIdentity(user: identity.userId, device: identity.deviceId)
            }
        }
    }

    func authenticatedSessionReady() {
        guard !isUITestFixture else { return }
        guard let user = appdelegate?.user?.userId, !user.isEmpty, !currentDeviceId.isEmpty else { return }
        guard ManagedIdentityRules.permitsSwitch(isSupervised: isSettingsLocked, currentUser: userId, newUser: user) else {
            clockStatus = "uncertain"
            syncState = .recovery
            lastError = ManagedBlockingText.value("accountMismatch", fallback: "This device is supervised for another account. Sign back into that account to verify its school settings.")
            updateNavigationGate()
            return
        }
        if ManagedIdentityRules.requiresManagedDeviceRecovery(isSupervised: isSettingsLocked, currentUser: userId, newUser: user, currentDevice: deviceId, newDevice: currentDeviceId) {
            recoverChangedDevice(currentDeviceId)
        } else if user != userId || currentDeviceId != deviceId { loadIdentity(user: user, device: currentDeviceId) }
        startTimer()
        refresh()
    }

    var isSignedInAsWrongAccount: Bool {
        !isUITestFixture && isSettingsLocked && appdelegate?.user?.userId != nil && appdelegate?.user?.userId != userId
    }

    func signOutWrongAccount() {
        if isSignedInAsWrongAccount { appdelegate?.logout(isAutomatic: false) }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }; observers.removeAll()
        persist()
    }

    func allowLegacySettingsMutation() -> Bool {
        guard isSettingsLocked else { return true }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = ManagedBlockingText.value("settingsLocked", fallback: "Settings are locked. A parent must approve home schedule changes.")
            alert.addButton(withTitle: ManagedBlockingText.value("close", fallback: "Close"))
                .setAccessibilityIdentifier(UITestContract.Identifier.ManagedSafety.settingsLockedAlertCloseButton)
            if let window = NSApp.keyWindow { alert.beginSheetModal(for: window, completionHandler: nil) }
            else { alert.runModal() }
        }
        return false
    }

    #if DEBUG
    /// A UI test's managed policy, in memory only (`UITestManagedSafetyFixture` gates it to the `.uitests`
    /// build launched with `--uiTest`). The store is never touched, so nothing reaches the keychain, and
    /// the timer never starts, so nothing refreshes, polls a browser or sends a receipt. The identity stays
    /// empty, which `ManagedBlockingAPI.request` refuses before any network call — so even the inspector's
    /// Refresh and the home editor's approval request stay on this Mac.
    func installForUITests(_ fixture: UITestManagedSafetyFixture.PolicyState) {
        isUITestFixture = true
        effectivePolicy = fixture.snapshot
        activePolicy = fixture.snapshot.activePolicy(at: fixture.now)
        isSettingsLocked = fixture.snapshot.settingsLocked
        syncState = fixture.syncState
        lastSyncedAt = fixture.lastSyncedAt
        clockStatus = "trusted"
        serverAnchor = fixture.now
        wallAnchor = Date(); uptimeAnchor = ProcessInfo.processInfo.systemUptime
        updateNavigationGate()
        addLog(text: "ManagedBlockingRuntime: UI-test policy installed (\(fixture.syncState.rawValue))")
    }
    #endif

    func checkCurrentBrowserNow() {
        DispatchQueue.main.async { if self.isSettingsLocked { self.pollBrowser() } }
    }

    /// A personal/AI-buddy callback cannot reopen a website already denied by the managed layer.
    func shouldDeferLegacyURL(_ value: String) -> Bool {
        guard let resource = ManagedResource(value) else { return navigationGate.deniesMalformedWebsite(value) }
        return navigationGate.denies(resource)
    }

    private func updateNavigationGate() {
        navigationGate.update(snapshot: effectivePolicy, managed: isSettingsLocked, session: sessionGeneration,
            recovery: syncState == .recovery || clockStatus != "trusted", denied: deniedResources, now: effectiveNow)
    }

    private func loadIdentity(user: String, device: String) {
        sessionGeneration = UUID()
        userId = user; deviceId = device
        currentRequest = nil; cachedClassifications.removeAll(); lastObservation = nil
        isRefreshing = false; isCheckingBrowser = false; isUploading = false; isRequestBusy = false
        reportedEvents.removeAll(); deniedResources.removeAll(); appealedResources.removeAll(); isStorageHealthy = true
        state = nil; effectivePolicy = nil; activePolicy = nil
        isSettingsLocked = store.isKnownManaged(userId: user, deviceId: device)
        do {
            state = try store.load(userId: user, deviceId: device)
            if let state = state {
                effectivePolicy = state.snapshot
                isSettingsLocked = isSettingsLocked || state.snapshot.settingsLocked
                let elapsed = Date().timeIntervalSince(state.receivedAt)
                serverAnchor = (state.snapshot.serverTime.flatMap(ManagedDate.parse) ?? state.receivedAt).addingTimeInterval(max(0, elapsed))
                wallAnchor = Date(); uptimeAnchor = ProcessInfo.processInfo.systemUptime
                // Uptime anchors do not survive process restart; wall time cannot renew trust.
                clockStatus = Date().timeIntervalSince(state.lastSeenAt) < -60 ? "rollback_detected" : "uncertain"
                lastSyncedAt = state.receivedAt
            }
            syncState = isSettingsLocked ? .offline : .unmanaged
        } catch { isStorageHealthy = false; enterRecovery("storageFailed") }
        validateLease()
        updateNavigationGate()
        updateCounts()
    }

    private func recoverChangedDevice(_ device: String) {
        // Enrollment follows the supervised account. A new local device identifier cannot clear it.
        sessionGeneration = UUID()
        deviceId = device
        currentRequest = nil; cachedClassifications.removeAll(); lastObservation = nil
        isRefreshing = false; isCheckingBrowser = false; isUploading = false; isRequestBusy = false
        appealedResources.removeAll()
        clockStatus = "uncertain"
        state?.deviceId = device
        do { try store.rememberManagedIdentity(userId: userId, deviceId: device) }
        catch { isStorageHealthy = false }
        enterRecovery("policyUnavailable")
        persist()
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.clockStatus = "uncertain"
            self.validateLease()
            self.refresh()
        })
    }

    private func tick() {
        validateLease()
        activePolicy = effectivePolicy?.activePolicy(at: effectiveNow)
        updateNavigationGate()
        if ProcessInfo.processInfo.systemUptime - lastRefresh >= 60 { refresh() }
        if ProcessInfo.processInfo.systemUptime - lastFlush >= 10 { flushViolations() }
        if isSettingsLocked { pollBrowser() }
        if isSettingsLocked && ProcessInfo.processInfo.systemUptime - lastReceipt >= 60 { sendReceipt(); persist() }
        if let request = currentRequest, ["pending", "approved", "proposed"].contains(request.status),
           ProcessInfo.processInfo.systemUptime - lastRequestPoll >= 5 { pollSettingsRequest() }
    }

    func refresh() {
        guard !isRefreshing, appdelegate?.user?.userId == userId, currentDeviceId == deviceId else { return }
        isRefreshing = true; lastRefresh = ProcessInfo.processInfo.systemUptime
        let generation = sessionGeneration
        let requestId = UUID(); snapshotRequestId = requestId
        api.request("effective-policy", identity: apiIdentity) { [weak self] (result: Result<ManagedPolicySnapshot, ManagedAPIError>) in
            guard let self = self, self.sessionGeneration == generation, self.snapshotRequestId == requestId else { return }
            self.isRefreshing = false
            switch result {
            case .success(let snapshot):
                self.apply(snapshot)
                self.sendReceipt()
            case .failure:
                self.syncState = self.isSettingsLocked ? .offline : .unmanaged
                self.lastError = ManagedBlockingText.value("syncFailed", fallback: "Could not refresh school settings. Cached restrictions remain in effect.")
                self.validateLease()
            }
        }
    }

    private func apply(_ snapshot: ManagedPolicySnapshot) {
        effectivePolicy = snapshot
        activePolicy = snapshot.activePolicy(at: snapshot.serverTime.flatMap(ManagedDate.parse) ?? effectiveNow)
        isSettingsLocked = snapshot.settingsLocked
        cachedClassifications.removeAll()
        lastSyncedAt = Date()
        wallAnchor = Date(); uptimeAnchor = ProcessInfo.processInfo.systemUptime
        if let instant = snapshot.serverTime.flatMap(ManagedDate.parse) {
            serverAnchor = instant; clockStatus = "trusted"
        } else { clockStatus = "uncertain" }
        state = ManagedStoredState(userId: userId, deviceId: deviceId, snapshot: snapshot,
            receivedAt: Date(), lastSeenAt: Date(), events: state?.events ?? [],
            quarantinedEvents: state?.quarantinedEvents ?? [], droppedEventCount: state?.droppedEventCount ?? 0)
        syncState = snapshot.settingsLocked ? .online : .unmanaged
        lastError = nil
        persist()
        validateLease()
        updateNavigationGate()
    }

    private func validateLease() {
        guard isSettingsLocked else { return }
        let expectedWall = wallAnchor.addingTimeInterval(ProcessInfo.processInfo.systemUptime - uptimeAnchor)
        if abs(Date().timeIntervalSince(expectedWall)) > 60 { clockStatus = "rollback_detected" }
        guard isStorageHealthy, let snapshot = effectivePolicy,
              ManagedPolicyLease.isUsable(snapshot, clockStatus: clockStatus, at: effectiveNow) else {
            enterRecovery("policyUnavailable"); return
        }
    }

    private func enterRecovery(_ key: String) {
        if isSettingsLocked { syncState = .recovery }
        updateNavigationGate()
        lastError = ManagedBlockingText.value(key, fallback: "School settings need verification. Essential Focus Bear support and sign-in remain available.")
    }

    private func persist() {
        guard var state = state else { return }
        state.lastSeenAt = Date()
        // An enrollment marker may be newer than the encrypted snapshot after an interrupted write.
        // Only apply() can confirm removal of supervision; persistence cannot clear that marker.
        if isSettingsLocked { state.snapshot.settingsLocked = true }
        if clockStatus == "trusted" {
            let cutoff = effectiveNow.addingTimeInterval(-90 * 86400)
            state.events.removeAll { ManagedDate.parse($0.observedAt).map { $0 < cutoff } ?? true }
            state.quarantinedEvents.removeAll { ManagedDate.parse($0.observedAt).map { $0 < cutoff } ?? true }
        }
        self.state = state
        do { try store.save(state); isStorageHealthy = true }
        catch { isStorageHealthy = false; enterRecovery("storageFailed") }
        updateCounts()
    }

    private func updateCounts() {
        queuedViolationCount = state?.events.count ?? 0
        rejectedViolationCount = (state?.quarantinedEvents.count ?? 0) + (state?.droppedEventCount ?? 0)
    }

    private var lastRequestPoll: TimeInterval = -.infinity

    func requestSettingsEdit(scope: [String]) {
        guard !isRequestBusy, isSettingsLocked, syncState == .online, clockStatus == "trusted",
              let home = effectivePolicy?.home, !scope.isEmpty,
              Set(scope).count == scope.count, scope.allSatisfy(ManagedPolicyChanges.editableFields.contains) else { return }
        let body = ManagedCreateSettingsRequest(deviceId: deviceId, scope: scope, baseRevision: home.revision)
        guard let data = try? ManagedJSON.encoder().encode(body) else { return }
        isRequestBusy = true
        sendSettingsRequest("settings-edit-requests", method: "POST", body: data)
    }

    func pollSettingsRequest() {
        guard !isRequestBusy, let request = currentRequest else { return }
        lastRequestPoll = ProcessInfo.processInfo.systemUptime; isRequestBusy = true
        sendSettingsRequest("settings-edit-requests/" + request.id)
    }

    func proposeSettingsChanges(_ changes: ManagedPolicyChanges) {
        guard !isRequestBusy, canProposeHomeChanges, let request = currentRequest else { return }
        let body = ManagedProposeSettingsChanges(deviceId: deviceId, changes: changes)
        guard let data = try? ManagedJSON.encoder().encode(body) else { return }
        isRequestBusy = true
        sendSettingsRequest("settings-edit-requests/" + request.id + "/propose", method: "POST", body: data)
    }

    private func sendSettingsRequest(_ route: String, method: String = "GET", body: Data? = nil) {
        let generation = sessionGeneration
        api.request(route, identity: apiIdentity, method: method, body: body) { [weak self] (result: Result<ManagedSettingsRequest, ManagedAPIError>) in
            guard let self = self, self.sessionGeneration == generation else { return }
            self.settingsResult(result)
        }
    }

    private func settingsResult(_ result: Result<ManagedSettingsRequest, ManagedAPIError>) {
        isRequestBusy = false
        switch result {
        case .success(let request):
            currentRequest = request
            if request.status == "committed" { refresh() }
        case .failure:
            lastError = ManagedBlockingText.value("requestFailed", fallback: "The parent approval request could not be updated. Settings remain locked.")
        }
    }

    private func pollBrowser() {
        guard !isCheckingBrowser else { return }
        guard activePolicy != nil || syncState == .recovery else { lastObservation = nil; return }
        guard UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) != nil else {
            permissionStatus = "missing"
            lastError = ManagedBlockingText.value("permissionMissing", fallback: "Browser permissions are missing. School website blocking cannot run until permissions are restored.")
            sendReceipt(); return
        }
        guard let app = NSWorkspace.shared.frontmostApplication, let name = app.localizedName,
              let browser = getCurrentBrowserFrom(browserName: name.lowercased()) else { lastObservation = nil; return }
        if browser != ._FIREFOX_ {
            let permissions = UserDefaults.standard.array(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String: Any]] ?? []
            guard permissions.contains(where: { ($0["browser"] as? Int) == browser.rawValue && ($0["isEnabled"] as? Bool) == true }) else {
                permissionStatus = "missing"
                lastError = ManagedBlockingText.value("permissionMissing", fallback: "Browser permissions are missing. School website blocking cannot run until permissions are restored.")
                sendReceipt(); return
            }
        }
        isCheckingBrowser = true
        let generation = sessionGeneration
        browserQueue.async {
            let observation = ManagedBrowserAccess.observe(browser)
            DispatchQueue.main.async {
                guard self.sessionGeneration == generation else { return }
                guard let observation = observation else {
                    self.permissionStatus = "missing"; self.isCheckingBrowser = false
                    self.lastError = ManagedBlockingText.value(browser == ._FIREFOX_ ? "firefoxUpgradeRequired" : "browserUnsupported",
                        fallback: "This browser cannot confirm managed website blocking. Check browser permissions and use a supported browser.")
                    self.sendReceipt(); return
                }
                let url = observation.url
                guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier else {
                    self.isCheckingBrowser = false; return
                }
                self.permissionStatus = self.failedBrowserIds.contains(browser.rawValue) ? "unknown" : "ready"
                guard let resource = ManagedResource(url) else {
                    self.isCheckingBrowser = false
                    if url.lowercased().hasPrefix("https://") || url.lowercased().hasPrefix("http://") {
                        self.handleMalformedWebsite(url, target: observation, browser: browser, processId: app.processIdentifier)
                    } else { self.lastObservation = nil }
                    return
                }
                self.evaluate(resource, target: observation, title: observation.title, browser: browser, processId: app.processIdentifier)
            }
        }
    }

    private func evaluate(_ resource: ManagedResource, target: ManagedBrowserObservation, title: String?, browser: BROWSER, processId: pid_t) {
        let observation = String(processId) + ":" + resource.hash
        if observation != lastObservation { eventId = UUID().uuidString; lastObservation = observation }
        if syncState == .recovery {
            isCheckingBrowser = false
            if !ManagedBrowserAccess.isEssential(resource) {
                enforce(resource, target: target, browser: browser, processId: processId, reason: "recovery", categories: [], violationId: nil)
            }
            return
        }
        guard let policy = activePolicy else { isCheckingBrowser = false; return }
        if policy.blockedCategories.isEmpty || ManagedPolicyEvaluator.matchesAllowlist(policy, url: resource.normalizedURL, at: effectiveNow) {
            isCheckingBrowser = false; return
        }
        let key = policy.id + ":" + String(policy.revision) + ":" + resource.hash + ":" + ManagedResource.hash(title ?? "")
        let cachedDecision = cachedClassifications[key].flatMap {
            ManagedPolicyEvaluator.cachedDecision($0, policy: policy, resource: resource, at: effectiveNow)
        }
        if !appealedResources.contains(resource.hash), let decision = cachedDecision,
           decision.allowed || syncState != .online {
            if !decision.allowed {
                recordOffline(resource, policy: policy, categories: decision.categories)
                enforce(resource, target: target, browser: browser, processId: processId, reason: decision.reason,
                    categories: decision.categories, violationId: nil)
            }
            isCheckingBrowser = false; return
        }
        // Online denials are rechecked to obtain an appealable server violation ID.
        let submittedEvent = eventId
        let generation = sessionGeneration
        let request = ManagedURLCheck(url: resource.normalizedURL, tabTitle: title.map { String($0.prefix(1000)) },
                                      deviceId: deviceId, eventId: submittedEvent)
        guard let data = try? ManagedJSON.encoder().encode(request) else { isCheckingBrowser = false; return }
        api.request("check-url", identity: apiIdentity, method: "POST", body: data) { [weak self] (result: Result<ManagedURLDecision, ManagedAPIError>) in
            guard let self = self, self.sessionGeneration == generation else { return }
            self.isCheckingBrowser = false
            guard self.effectivePolicy?.activePolicy(at: self.effectiveNow)?.id == policy.id, self.effectivePolicy?.activePolicy(at: self.effectiveNow)?.revision == policy.revision,
                  self.syncState != .recovery else { return }
            switch result {
            case .success(let decision):
                if decision.reason == "policy_changed_retry" { self.refresh(); return }
                guard decision.policy?.id == policy.id, decision.policy?.revision == policy.revision else { self.refresh(); return }
                if decision.appeal == nil, let classification = decision.classification,
                   let expiry = ManagedDate.parse(classification.expiresAt), expiry > self.effectiveNow {
                    if self.cachedClassifications.count >= 256 { self.cachedClassifications.removeAll() }
                    self.cachedClassifications[key] = classification
                }
                if decision.allowed {
                    self.deniedResources.remove(policy.id + ":" + String(policy.revision) + ":" + resource.hash)
                    self.updateNavigationGate()
                }
                if !decision.allowed {
                    if decision.violationId != nil {
                        if self.reportedEvents.count >= 256 { self.reportedEvents.removeAll() }
                        self.reportedEvents.insert(submittedEvent)
                    }
                    self.enforce(resource, target: target, browser: browser, processId: processId, reason: decision.reason,
                                 categories: decision.matchedCategories ?? [], violationId: decision.violationId)
                }
            case .failure:
                self.syncState = .offline
                let decision = self.cachedClassifications[key].flatMap {
                    ManagedPolicyEvaluator.cachedDecision($0, policy: policy, resource: resource, at: self.effectiveNow)
                } ?? ManagedPolicyEvaluator.offlineDecision(policy, url: resource.normalizedURL, at: self.effectiveNow)
                if !decision.allowed {
                    self.recordOffline(resource, policy: policy, categories: decision.categories, eventId: submittedEvent)
                    self.enforce(resource, target: target, browser: browser, processId: processId, reason: decision.reason,
                                 categories: decision.categories, violationId: nil)
                }
            }
        }
    }

    private func handleMalformedWebsite(_ url: String, target: ManagedBrowserObservation, browser: BROWSER, processId: pid_t) {
        let policy = effectivePolicy?.activePolicy(at: effectiveNow)
        let recovery = syncState == .recovery
        guard recovery || (policy.map { !$0.blockedCategories.isEmpty &&
            ($0.unavailableAction != "allow" || $0.blockedCategories.contains("not_resolved")) } ?? false) else { return }
        let observation = "invalid:" + ManagedResource.hash(url)
        if lastObservation != observation {
            lastObservation = observation
            // No canonical resource identity exists. Do not invent a hash meaning for backend replay.
            state?.droppedEventCount += 1
            persist()
        }
        let binding = ManagedEnforcementBinding(snapshotId: effectivePolicy?.snapshotId, session: sessionGeneration,
            policyId: policy?.id, revision: policy?.revision, recovery: recovery)
        let generation = sessionGeneration
        browserQueue.async {
            guard self.navigationGate.permits(binding),
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == processId,
                  ManagedBrowserAccess.navigate(browser, to: "about:blank", expectedURL: url, target: target, authorization: { self.navigationGate.permits(binding) && (browser == ._FIREFOX_ || NSWorkspace.shared.frontmostApplication?.processIdentifier == processId) }) else {
                self.recordNavigationFailure(browser: browser, target: target, binding: binding); return
            }
            DispatchQueue.main.async {
                guard generation == self.sessionGeneration, self.navigationGate.permits(binding) else { return }
                self.failedBrowserIds.remove(browser.rawValue)
                self.lastError = ManagedBlockingText.value("malformedWebsite", fallback: "A website address could not be safely classified. Access was blocked, but this attempt could not be synced.")
                ManagedBlockPresentation.shared.showMalformedWebsite(runtime: self)
            }
        }
    }

    private func enforce(_ resource: ManagedResource, target: ManagedBrowserObservation, browser: BROWSER, processId: pid_t,
                         reason: String, categories: [String], violationId: String?) {
        if let policy = activePolicy {
            if deniedResources.count >= 512 { deniedResources.removeAll() }
            deniedResources.insert(policy.id + ":" + String(policy.revision) + ":" + resource.hash)
        }
        updateNavigationGate()
        let binding = ManagedEnforcementBinding(snapshotId: effectivePolicy?.snapshotId, session: sessionGeneration,
            policyId: activePolicy?.id, revision: activePolicy?.revision, recovery: reason == "recovery")
        let generation = sessionGeneration
        browserQueue.async {
            guard let observation = ManagedBrowserAccess.observe(browser), observation.windowId == target.windowId,
                  observation.tabId == target.tabId, ManagedResource(observation.url)?.hash == resource.hash else { return }
            let current = observation.url
            DispatchQueue.main.async {
                guard self.sessionGeneration == generation, self.navigationGate.permits(binding),
                      NSWorkspace.shared.frontmostApplication?.processIdentifier == processId else { return }
                self.browserQueue.async {
                    guard self.navigationGate.permits(binding),
                          ManagedBrowserAccess.navigate(browser, to: "about:blank", expectedURL: current, target: target, authorization: { self.navigationGate.permits(binding) && (browser == ._FIREFOX_ || NSWorkspace.shared.frontmostApplication?.processIdentifier == processId) }) else {
                        self.recordNavigationFailure(browser: browser, target: target, binding: binding); return
                    }
                    DispatchQueue.main.async {
                        guard self.sessionGeneration == generation, self.navigationGate.permits(binding) else { return }
                        self.failedBrowserIds.remove(browser.rawValue)
                        ManagedBlockPresentation.shared.show(resource: resource, browser: browser,
                            target: target, reason: reason, categories: categories, violationId: violationId, runtime: self)
                    }
                }
            }
        }
    }

    private func recordNavigationFailure(browser: BROWSER, target: ManagedBrowserObservation, binding: ManagedEnforcementBinding) {
        guard navigationGate.permits(binding) else { return }
        if let current = ManagedBrowserAccess.observe(browser),
           current.windowId != target.windowId || current.tabId != target.tabId || current.url != target.url { return }
        DispatchQueue.main.async {
            guard self.navigationGate.permits(binding) else { return }
            self.failedBrowserIds.insert(browser.rawValue)
            self.permissionStatus = "unknown"
            self.lastError = ManagedBlockingText.value("browserUnsupported", fallback: "This browser cannot confirm managed website blocking. Check browser permissions and use a supported browser.")
            self.sendReceipt()
        }
    }

    private func recordOffline(_ resource: ManagedResource, policy: ManagedPolicy, categories: [String], eventId: String? = nil) {
        let id = eventId ?? self.eventId
        guard !reportedEvents.contains(id) else { return }
        guard state?.events.contains(where: { $0.eventId == id }) == false else { return }
        let event = ManagedViolationEvent(eventId: id, deviceId: deviceId, policyId: policy.id,
            policyRevision: policy.revision, domain: resource.host.trimmingCharacters(in: CharacterSet(charactersIn: "[]")),
            resourceHash: resource.hash, categoryIds: categories, observedAt: ManagedDate.string(effectiveNow))
        if (state?.events.count ?? 0) >= 2000 { state?.droppedEventCount += 1 }
        else { state?.events.append(event) }
        persist()
    }

    private func flushViolations() {
        guard !isUploading, appdelegate?.user?.userId == userId,
              let batch = state?.events.prefix(50), !batch.isEmpty else { return }
        lastFlush = ProcessInfo.processInfo.systemUptime; isUploading = true
        let generation = sessionGeneration
        let events = Array(batch)
        guard let data = try? ManagedJSON.encoder().encode(ManagedViolationBatch(events: events)) else { isUploading = false; return }
        api.request("violations/batch", identity: apiIdentity, method: "POST", body: data) { [weak self] (result: Result<ManagedViolationResults, ManagedAPIError>) in
            guard let self = self, self.sessionGeneration == generation else { return }
            self.isUploading = false
            guard case .success(let response) = result else { return }
            let expected = Set(events.map(\.eventId))
            guard response.results.count == expected.count, Set(response.results.map(\.eventId)) == expected else { return }
            for item in response.results {
                if item.status == "accepted", item.violationId != nil {
                    self.state?.events.removeAll { $0.eventId == item.eventId }
                } else if item.status == "rejected", item.retryable == false,
                          let event = self.state?.events.first(where: { $0.eventId == item.eventId }) {
                    if (self.state?.quarantinedEvents.count ?? 0) < 2000 { self.state?.quarantinedEvents.append(event) }
                    else { self.state?.droppedEventCount += 1 }
                    self.state?.events.removeAll { $0.eventId == item.eventId }
                }
            }
            self.persist()
        }
    }

    private func sendReceipt() {
        guard ProcessInfo.processInfo.systemUptime - lastReceipt >= 30, let snapshot = effectivePolicy,
              let snapshotId = snapshot.snapshotId, appdelegate?.user?.userId == userId else { return }
        lastReceipt = ProcessInfo.processInfo.systemUptime
        let policies = [snapshot.school, snapshot.home].compactMap { $0 }.map {
            ManagedDeviceReceipt.AppliedPolicy(id: $0.id, kind: $0.kind, revision: $0.revision)
        }
        let status = syncState == .recovery ? "recovery" : (permissionStatus == "ready" && isStorageHealthy ? (activePolicy == nil ? "inactive" : "enforcing") : "error")
        let receipt = ManagedDeviceReceipt(deviceId: deviceId, snapshotId: snapshotId, appliedPolicies: policies,
            clientVersion: getAppVersionInString(), clockStatus: clockStatus, permissionStatus: permissionStatus,
            syncStatus: syncState == .online ? "online" : "offline", enforcementStatus: status, observedAt: ManagedDate.string(effectiveNow))
        guard let data = try? ManagedJSON.encoder().encode(receipt) else { return }
        api.request("device-receipts", identity: apiIdentity, method: "POST", body: data) { [weak self] (result: Result<ManagedEmptyResponse, ManagedAPIError>) in
            if case .failure(.status(409)) = result { self?.refresh() }
        }
    }

    func submitAppeal(violationId: String, explanation: String, expectedSession: UUID,
                      completion: @escaping (Result<ManagedAppeal, ManagedAPIError>) -> Void) {
        guard sessionGeneration == expectedSession, syncState == .online, clockStatus == "trusted",
              let data = try? ManagedJSON.encoder().encode(ManagedAppealExplanation(explanation: explanation)) else {
            completion(.failure(.transport)); return
        }
        api.request("violations/" + violationId + "/appeals", identity: apiIdentity, method: "POST", body: data) {
            [weak self] (result: Result<ManagedAppeal, ManagedAPIError>) in
            guard self?.sessionGeneration == expectedSession else { completion(.failure(.authentication)); return }
            completion(result)
        }
    }

    func recheckForAppeal(_ resource: ManagedResource, expectedSession: UUID,
                         completion: @escaping (Result<ManagedURLDecision, ManagedAPIError>) -> Void) {
        guard sessionGeneration == expectedSession else { completion(.failure(.authentication)); return }
        // Refresh the lease first. An offline notice can then become an online, appealable denial.
        let requestId = UUID(); snapshotRequestId = requestId; isRefreshing = true
        lastRefresh = ProcessInfo.processInfo.systemUptime
        api.request("effective-policy", identity: apiIdentity) { [weak self] (result: Result<ManagedPolicySnapshot, ManagedAPIError>) in
            guard let self = self, self.sessionGeneration == expectedSession, self.snapshotRequestId == requestId else { completion(.failure(.authentication)); return }
            self.isRefreshing = false
            guard case .success(let snapshot) = result else { completion(.failure(.transport)); return }
            self.apply(snapshot)
            guard self.syncState != .recovery, self.clockStatus == "trusted" else { completion(.failure(.invalidResponse)); return }
            let body = ManagedURLCheck(url: resource.normalizedURL, deviceId: self.deviceId, eventId: UUID().uuidString)
            guard let data = try? ManagedJSON.encoder().encode(body) else { completion(.failure(.invalidResponse)); return }
            self.api.request("check-url", identity: self.apiIdentity, method: "POST", body: data) {
                [weak self] (decision: Result<ManagedURLDecision, ManagedAPIError>) in
                guard self?.sessionGeneration == expectedSession else { completion(.failure(.authentication)); return }
                completion(decision)
            }
        }
    }

    func revisit(_ resource: ManagedResource, browser: BROWSER, target: ManagedBrowserObservation,
                 expectedSession: UUID, completion: @escaping (Bool) -> Void) {
        guard sessionGeneration == expectedSession, [.online, .unmanaged].contains(syncState), clockStatus == "trusted" else { completion(false); return }
        let snapshotId = effectivePolicy?.snapshotId
        let policy = effectivePolicy?.activePolicy(at: effectiveNow)
        let body = ManagedURLCheck(url: resource.normalizedURL, deviceId: deviceId, eventId: UUID().uuidString)
        guard let data = try? ManagedJSON.encoder().encode(body) else { completion(false); return }
        api.request("check-url", identity: apiIdentity, method: "POST", body: data) { (result: Result<ManagedURLDecision, ManagedAPIError>) in
            guard self.sessionGeneration == expectedSession, self.effectivePolicy?.snapshotId == snapshotId,
                  [.online, .unmanaged].contains(self.syncState), self.clockStatus == "trusted",
                  self.effectivePolicy?.activePolicy(at: self.effectiveNow)?.id == policy?.id,
                  self.effectivePolicy?.activePolicy(at: self.effectiveNow)?.revision == policy?.revision,
                  case .success(let decision) = result, decision.allowed,
                  decision.policy?.id == policy?.id, decision.policy?.revision == policy?.revision else { completion(false); return }
            self.appealedResources.insert(resource.hash)
            self.cachedClassifications = self.cachedClassifications.filter { !$0.key.contains(resource.hash) }
            self.deniedResources.remove((policy?.id ?? "") + ":" + String(policy?.revision ?? 0) + ":" + resource.hash)
            self.updateNavigationGate()
            let binding = ManagedEnforcementBinding(snapshotId: snapshotId, session: expectedSession,
                policyId: policy?.id, revision: policy?.revision, recovery: false)
            self.browserQueue.async {
                let applied = ManagedBrowserAccess.navigate(browser, to: resource.normalizedURL, expectedURL: "about:blank", target: target,
                    authorization: { self.navigationGate.permitsRevisit(binding) })
                DispatchQueue.main.async { completion(applied) }
            }
        }
    }
}
