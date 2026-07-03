//
//  WiFiMonitorService.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-05-19.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Implements #1000 — Auto switch to WFH/office depending on wifi network you connect to
//  Uses CoreWLAN (CWWiFiClient) to monitor SSID changes and switch the active Focus Bear
//  profile when the user moves between configured networks.
//
//  macOS 10.15+ requires Location Services to read the SSID.  The app must include
//  NSLocationWhenInUseUsageDescription (or NSLocationAlwaysUsageDescription) in Info.plist
//  and request authorisation before calling this service.
//

import CoreWLAN
import Foundation

// MARK: - Notification

extension Notification.Name {
    /// Posted on the main queue whenever the active SSID changes.
    /// `userInfo["ssid"]` contains the new SSID (String?) — nil means disconnected.
    static let wifiSSIDDidChange = Notification.Name("com.focusbear.wifiSSIDDidChange")
}

// MARK: - WiFiMonitorService

/// Singleton that monitors Wi-Fi SSID changes and fires profile-switching logic.
final class WiFiMonitorService: NSObject {

    // MARK: Singleton
    static let shared = WiFiMonitorService()

    // MARK: Private state

    private let wifiClient = CWWiFiClient.shared()

    /// Serial queue used to protect all mutable state (isMonitoring, currentSSID, pollingTimer).
    /// All public methods and delegate callbacks must hop onto this queue before touching state.
    private let stateQueue = DispatchQueue(label: "com.focusbear.WiFiMonitorService.state")

    private var currentSSID: String?
    private var _isMonitoring = false

    private var isMonitoring: Bool {
        get { stateQueue.sync { _isMonitoring } }
        set { stateQueue.sync { _isMonitoring = newValue } }
    }

    private override init() {
        super.init()
    }

    // MARK: - Public API

    /// Start watching for SSID changes.  Safe to call multiple times.
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // NB: we deliberately do NOT request Location authorisation here. macOS 10.15+ needs
        // Location Services before CoreWLAN returns a real SSID, but we don't want to nag the
        // user at launch — the prompt is only raised when they open the Office Mode settings
        // and tap "Use Current Network" (officeModeSettingsVc). Until then SSID reads return nil
        // and auto-switching stays dormant, which is the intended behaviour.

        // Seed the current SSID so we don't fire a spurious change on first tick.
        // All access to currentSSID must go through stateQueue to avoid data races with
        // the CoreWLAN delegate callbacks and the polling timer.
        let seededSSID = readCurrentSSID()
        stateQueue.sync { currentSSID = seededSSID }
        addLog(text: "WiFiMonitorService: startMonitoring — initial SSID present = \(seededSSID != nil)")

        // Register for CWWiFiClient interface-event notifications.
        do {
            try wifiClient.startMonitoringEvent(with: .ssidDidChange)
            wifiClient.delegate = self
            addLog(text: "WiFiMonitorService: CoreWLAN event monitoring started")
        } catch {
            addLog(text: "WiFiMonitorService: CoreWLAN startMonitoringEvent failed: \(error.localizedDescription)")
            // Fallback: poll every 30 s — must be scheduled on the main run loop.
            startPollingFallback()
        }
    }

    /// Stop watching for SSID changes.
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        // Silence delegate callbacks AND stop CoreWLAN from generating events.
        wifiClient.delegate = nil
        try? wifiClient.stopMonitoringEvent(with: .ssidDidChange)
        // Cancel polling fallback if active.
        DispatchQueue.main.async { [weak self] in
            self?.pollingTimer?.invalidate()
            self?.pollingTimer = nil
        }
        addLog(text: "WiFiMonitorService: monitoring stopped")
    }

    // MARK: - SSID reading

    /// Returns the current SSID, or nil when disconnected / permission denied.
    func readCurrentSSID() -> String? {
        return wifiClient.interface()?.ssid()
    }


    // MARK: - Switching logic

    /// Called whenever we detect an SSID change.  Looks up the new SSID in the
    /// user-configured mappings and triggers a profile switch if matched.
    private func handleSSIDChange(newSSID: String?) {
        // Guard: only process genuine changes.
        // NOTE: `return` inside a `stateQueue.sync {}` closure exits the closure, not this
        // function. We capture the result as a Bool so the enclosing function can early-exit.
        let didChange = stateQueue.sync { () -> Bool in
            guard newSSID != currentSSID else { return false }
            currentSSID = newSSID
            return true
        }
        guard didChange else { return }

        // Log event without revealing the plaintext SSID to avoid leaking network topology.
        addLog(text: "WiFiMonitorService: SSID changed — connected = \(newSSID != nil)")

        // Capture PostHog event. Omit SSID entirely — String.hash is non-deterministic
        // across process launches (Swift 4.2+) so it is useless for cohort analysis,
        // and logging the real SSID would leak sensitive network data.
        allApiObject.capturePosthog(
            event: "wifi-ssid-changed",
            metadata: ["connected": newSSID != nil ? "true" : "false"]
        )

        NotificationCenter.default.post(
            name: .wifiSSIDDidChange,
            object: self,
            userInfo: ["ssid": newSSID as Any]
        )

        guard let ssid = newSSID else {
            // Disconnected: transient/ambiguous, so keep the current mode rather than
            // flapping to Office on every brief Wi-Fi drop.
            addLog(text: "WiFiMonitorService: disconnected from Wi-Fi — keeping current mode")
            return
        }

        let mappings = WiFiProfileMapping.loadAll()
        guard !mappings.isEmpty else {
            // Feature not configured — don't take over the mode until the user adds a network.
            addLog(text: "WiFiMonitorService: no Wi-Fi networks configured — auto-switch idle")
            return
        }

        // Default to Office unless THIS network is explicitly marked WFH. So unmapped
        // networks (and ones marked Office) all resolve to Office; only a WFH-marked
        // network switches to WFH. Matches applyProfile's `== "office"` interpretation.
        let match = mappings.first(where: { $0.ssid == ssid })
        let isWFHNetwork = (match?.profileName.lowercased() ?? "office") != "office"
        let profile = isWFHNetwork ? "wfh" : "office"

        // Skip if we're already in the target mode, so we don't rebuild break activities
        // or fire analytics on every network change that doesn't actually change the mode.
        if SettingsManagerObject.isOfficeModeEnabled == !isWFHNetwork {
            addLog(text: "WiFiMonitorService: already in \(profile) mode — no change")
            return
        }

        addLog(text: "WiFiMonitorService: SSID \(match == nil ? "unmapped" : "mapped '\(match!.profileName)'") — switching to \(profile)")
        switchToProfile(named: profile)
    }

    private func switchToProfile(named profileName: String) {
        allApiObject.capturePosthog(
            event: "wifi-profile-auto-switched",
            metadata: ["profile": profileName]
        )
        // SettingsManagerObject is the global shared instance of SettingsManager
        // (declared in globalFile.swift: `var SettingsManagerObject = SettingsManager()`).
        // This is an instance method call, NOT a static/type call.
        SettingsManagerObject.applyProfile(named: profileName)
    }

    // MARK: - Polling fallback

    private var pollingTimer: Timer?

    private func startPollingFallback() {
        addLog(text: "WiFiMonitorService: falling back to 30-second SSID polling")
        // Timer must be scheduled on the main run loop so it fires reliably.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let newSSID = self.readCurrentSSID()
                // Read currentSSID through stateQueue to avoid a data race with the
                // CoreWLAN delegate callbacks. handleSSIDChange re-checks under the lock,
                // so this is purely an optimisation to skip the no-op case safely.
                let previousSSID = self.stateQueue.sync { self.currentSSID }
                if newSSID != previousSSID {
                    self.handleSSIDChange(newSSID: newSSID)
                }
            }
        }
    }
}

// MARK: - CWEventDelegate

extension WiFiMonitorService: CWEventDelegate {
    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newSSID = self.wifiClient.interface(withName: interfaceName)?.ssid()
            self.handleSSIDChange(newSSID: newSSID)
        }
    }
}

// MARK: - SettingsManager extension

extension SettingsManager {
    func applyProfile(named profileName: String) {
        addLog(text: "SettingsManager.applyProfile: switching to '\(profileName)'")
        let enableOfficeMode = profileName.lowercased() == "office"
        DispatchQueue.main.async {
            if enableOfficeMode {
                SettingsManagerObject.isOfficeModeEnabled = true
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
                appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
                NSApplication.shared.applicationIconImage = NSImage(named: NSImage.Name("Bear-Office-icon"))
            } else {
                SettingsManagerObject.isOfficeModeEnabled = false
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
                appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
                NSApplication.shared.applicationIconImage = nil
            }
            getHabitsVcObject().reFillBreakActivitiesArray()
            addLog(text: "SettingsManager.applyProfile: office mode set to \(enableOfficeMode)")
        }
    }
}
