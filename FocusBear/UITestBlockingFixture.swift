//
//  UITestBlockingFixture.swift
//  Focus Bear
//
//  What the blocking UI tests block (docs/ui-tests.md). The test asks for a fixture through the
//  environment; the app sets it up through its own settings and API paths — the same ones the editors
//  use — so enforcement is exercised end to end without scripting the editors, which have their own
//  tests. Everything it creates is named with `BlockingFixture.namePrefix`, and the cleanup fixture
//  removes all of it, including leftovers from a run that crashed.
//
//  Only ever active in the isolated test build with blocking opted in (`UITestHost.isBlockingEnabled`).
//

import Cocoa

enum UITestBlockingFixture {
    private typealias Fixture = UITestContract.BlockingFixture

    /// Cleanup's deletes and the settings sync are fire-and-forget calls; give them this long to land
    /// before the app quits.
    private static let cleanupSettleSeconds = 5.0
    private static let cleanupRequestTimeoutSeconds = 20.0
    private static let secondsPerMinute = 60.0
    private static let everyWeekday = Array(1...7)
    private static var hasRun = false

    /// The only way in: a Debug build under the isolated `.uitests` id, launched by XCUITest with
    /// `--uiTest`, the blocking opt-in and a fixture named. The shipping app can never get here.
    private static var requestedKind: Fixture.Kind? {
        guard UITestHost.isBlockingEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest),
              let raw = ProcessInfo.processInfo.environment[UITestContract.Environment.blockingFixture] else { return nil }
        return Fixture.Kind(rawValue: raw)
    }

    /// Called from the launch tick once settings have loaded; runs at most once per launch.
    static func applyIfRequested() {
        guard !hasRun, let kind = requestedKind else { return }
        hasRun = true
        addLog(text: "UITestBlockingFixture: \(kind.rawValue)")
        // Onboarding normally records this; the URL checks do nothing until it is set.
        UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        switch kind {
        case .alwaysBlocked:
            addToAlwaysBlockedLists()
            publishStatus(kind, failure: nil)
        case .focusSession:
            startFocusSession()
        case .blockingSchedule:
            startBlockingSchedule()
        case .cleanup:
            cleanUpAndQuit()
        }
    }

    // MARK: - Set-up

    private static func addToAlwaysBlockedLists() {
        let settings = SettingsManagerObject
        if !settings.arrBlockedUrls.contains(Fixture.blockedDomain) { settings.arrBlockedUrls.append(Fixture.blockedDomain) }
        if !settings.arrBlockedApps.contains(Fixture.blockedAppPath) { settings.arrBlockedApps.append(Fixture.blockedAppPath) }
        persistAlwaysBlockedLists()
    }

    private static func startFocusSession() {
        guard let index = addBlockList() else { return publishStatus(.focusSession, failure: "could not add the block list") }
        let result = startFocusModeFromFocusDeviceButton(diffMinutes: Fixture.sessionMinutes, shouldUpdateFocusButton: false,
                                                         goal: Fixture.namePrefix, initiatedByRecording: false,
                                                         focusModeIndex: index)
        publishStatus(.focusSession, failure: result == .started ? nil : "session did not start: \(result)")
    }

    private static func startBlockingSchedule() {
        let now = Date()
        let start = now.addingTimeInterval(-Double(Fixture.scheduleLeadMinutes) * secondsPerMinute)
        let end = now.addingTimeInterval(Double(Fixture.scheduleMinutes) * secondsPerMinute)
        guard Calendar.current.isDate(start, inSameDayAs: end) else {
            return publishStatus(.blockingSchedule, failure: "a schedule covering now would cross midnight")
        }
        guard let index = addBlockList(), let blockListId = arrFocusType[index]["id"] as? String else {
            return publishStatus(.blockingSchedule, failure: "could not add the block list")
        }
        let schedule = customBlockingSchedule(id: getUuid(), name: fixtureName(), start: hoursAndMinutes(start),
                                              end: hoursAndMinutes(end), daysOfWeek: everyWeekday,
                                              focusModeID: blockListId, blockLevel: ._NORMAL_,
                                              isAIBlockingEnabled: false, isMicroBreaksEnabled: false)
        let manager = customBlockingScheduleManagerObj
        manager.arrBlockingSchedule.append(schedule)
        manager.saveBlockingSchedulesToLocal()
        manager.addCustomBlockingScheduleAtIndex(manager.arrBlockingSchedule.count - 1)
        manager.checkCustomBlockingScheduleTime()
        publishStatus(.blockingSchedule, failure: manager.isAnyCustomScheduleOn ? nil : "the schedule did not start")
    }

    /// An allow-list block list: example.org allowed, example.com and TextEdit blocked outright, AI
    /// off so the verdict never depends on a model. Every other app stays allowed, so the suite's own
    /// runner and the browser under test are never hidden. Returns its index in `arrFocusType`.
    private static func addBlockList() -> Int? {
        let id = getUuid()
        let blockList: [String: Any] = [
            "id": id, "name": fixtureName(), "tags": [String](),
            "allowed_urls": [Fixture.allowedDomain], "allowed_apps": [String](),
            "blockUrlsArray": [Fixture.blockedDomain], "blockAppsArray": [Fixture.blockedAppPath],
            "isAllowedListApproach": true, "isAllowedAllApps": true, "isOn": false,
            "is_ai_enabled": false,
        ]
        arrFocusType.append(blockList)
        SensitiveDefaults.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: blockList) { isAdded in
            if !isAdded { addLog(text: "UITestBlockingFixture: the block list was not saved to the server") }
        }
        return arrFocusType.firstIndex { $0["id"] as? String == id }
    }

    // MARK: - Cleanup

    private static func cleanUpAndQuit() {
        if isFocusModeOn(), isFixture(currentRunningFocusType["name"] as? String) {
            finishFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: false)
        }
        let requests = DispatchGroup()
        removeFixtureSchedules(tracking: requests)
        removeFixtureBlockLists(tracking: requests)
        removeFromAlwaysBlockedLists()
        DispatchQueue.global().async {
            _ = requests.wait(timeout: .now() + cleanupRequestTimeoutSeconds)
            Thread.sleep(forTimeInterval: cleanupSettleSeconds)
            DispatchQueue.main.async {
                // A plain terminate runs the user-quit flow, which a password-protected quit cancels.
                // Only reachable through `requestedKind`'s test-build gate.
                appdelegate?.terminateFromSelf = true
                NSApp.terminate(nil)
            }
        }
    }

    private static func removeFixtureSchedules(tracking requests: DispatchGroup) {
        let manager = customBlockingScheduleManagerObj
        let fixtures = manager.arrBlockingSchedule.filter { isFixture($0.name) }
        guard !fixtures.isEmpty else { return }
        if manager.runningSchedule.map({ isFixture($0.name) }) == true { manager.customBlockingScheduleFinished() }
        for schedule in fixtures {
            requests.enter()
            allApiObject.deleteBlockingSchedule(id: schedule.id) { _ in requests.leave() }
        }
        manager.arrBlockingSchedule.removeAll { isFixture($0.name) }
        manager.saveBlockingSchedulesToLocal()
    }

    private static func removeFixtureBlockLists(tracking requests: DispatchGroup) {
        let fixtureIds = arrFocusType.filter { isFixture($0["name"] as? String) }.compactMap { $0["id"] as? String }
        let context = LegacySettingsMutationContext.captureCurrent()
        for id in fixtureIds {
            requests.enter()
            allApiObject.deleteFocusMode(id: id, mutationContext: context) { _ in requests.leave() }
        }
        arrFocusType.removeAll { isFixture($0["name"] as? String) }
        SensitiveDefaults.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
    }

    private static func removeFromAlwaysBlockedLists() {
        let settings = SettingsManagerObject
        settings.arrBlockedUrls.removeAll { $0 == Fixture.blockedDomain }
        settings.arrBlockedApps.removeAll { $0 == Fixture.blockedAppPath }
        persistAlwaysBlockedLists()
    }

    // MARK: - Helpers

    private static func persistAlwaysBlockedLists() {
        let settings = SettingsManagerObject
        SensitiveDefaults.set(settings.arrBlockedUrls, forKey: settings.kUserdefaultsArrBlockedUrls)
        SensitiveDefaults.set(settings.arrBlockedApps, forKey: settings.kUserdefaultsArrBlockedApps)
        settings.isSettingsChanged = true
        settings.putUserLocalDeviceSettings()
    }

    private static func fixtureName() -> String {
        "\(Fixture.namePrefix) \(getUuid().prefix(8))"
    }

    private static func isFixture(_ name: String?) -> Bool {
        name?.hasPrefix(Fixture.namePrefix) == true
    }

    private static func hoursAndMinutes(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func publishStatus(_ kind: Fixture.Kind, failure: String?) {
        let safari = NSAppleEventDescriptor(bundleIdentifier: Fixture.browserBundleIdentifier)
        let status = Fixture.Status(kind: kind, isApplied: failure == nil, failure: failure,
                                    hasAccessibility: isAccessibilityEnabled(isPrompt: false),
                                    safariAutomationStatus: AEDeterminePermissionToAutomateTarget(safari.aeDesc, typeWildCard, typeWildCard, false))
        guard let json = try? JSONEncoder().encode(status) else { return }
        appdelegate?.statusbutton?.setAccessibilityValue(String(decoding: json, as: UTF8.self))
    }
}
