//
//  quickLookPreviewMonitor.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Quick Look previews (Finder's space-bar panel, attachment previews in Mail/Slack/…) are rendered by
//  the `QuickLookUIService` XPC service, not by the host app. The service has a "prohibited" activation
//  policy, so opening a preview never fires NSWorkspace.didActivateApplicationNotification: the host
//  (usually Finder, a default-allowed app) stays frontmost and app blocking never sees the file. This
//  monitor polls for open previews while blocking is enforced and gives each one the verdict the file's
//  DEFAULT APP would get from the running block list — allowed / blocked by the list, or, when the block
//  list uses AI relevance checking, the same AI app-relevance check apps get (on the file name + type).
//

import Cocoa
import ApplicationServices
import UniformTypeIdentifiers

let quickLookServiceBundleIdentifier = "com.apple.quicklook.QuickLookUIService"

/// Score at or above which the AI relevance check (`chatGPTIsAppSafe` / `chatGPTIsURLSafe`) counts as
/// "allowed". Existing call sites still compare against the literal.
let aiAllowedProbabilityThreshold = 0.70

func isQuickLookService(_ app: NSRunningApplication) -> Bool {
    return app.bundleIdentifier == quickLookServiceBundleIdentifier
}

/// One open Quick Look preview window.
struct QuickLookPreview {
    /// The preview panel's window title — Quick Look titles it with the previewed file's name.
    let fileName: String
    /// The previewed file when the window exposes it (AXDocument); lets the verdict honour a per-file
    /// "Open with" override. nil when only the name is known.
    let fileURL: URL?
    /// The QuickLookUIService process hosting the preview.
    let service: NSRunningApplication
    /// The preview panel's accessibility window.
    let window: AXUIElement
}

/// What the running block list says about the app a previewed file would open with.
enum QuickLookVerdict {
    case allowed
    case blocked
    /// Not on any list — the same situation in which an app goes to the AI relevance check (or is
    /// blocked outright when AI blocking is off).
    case needsRelevanceCheck
}

final class quickLookPreviewMonitor {

    static let shared = quickLookPreviewMonitor()

    private init() {}

    private let pollIntervalSeconds: TimeInterval = 1
    /// Never block on an unresponsive service — a missed poll is retried a second later (see claudeTitleReader).
    private let axMessagingTimeoutSeconds: Float = 0.5
    /// How long after pressing the panel's close button to wait before falling back to killing the service.
    private let closeVerifyDelaySeconds: TimeInterval = 0.4
    private let queue = DispatchQueue(label: "com.focusbear.quicklook-preview-monitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    /// The preview currently open and already judged (nil once it closes), so each opening is judged once
    /// and a preview left open while its AI check / block popup is pending isn't re-submitted every tick.
    private var judgedFileName: String?

    func start() {
        if UITestHost.suppressesEnforcement { return }
        queue.async {
            guard self.timer == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + self.pollIntervalSeconds, repeating: self.pollIntervalSeconds)
            timer.setEventHandler { [weak self] in self?.tick() }
            timer.resume()
            self.timer = timer
        }
    }

    // MARK: - Polling

    private func tick() {
        guard isBlockingEnforced() else {
            judgedFileName = nil
            return
        }
        guard let preview = openPreviews().first else {
            if let closedFileName = judgedFileName {
                DispatchQueue.main.async { focusModeCloseAppForAlignmentScore(appNameLowercased: closedFileName.lowercased()) }
            }
            judgedFileName = nil
            return
        }
        guard preview.fileName != judgedFileName else { return }
        judgedFileName = preview.fileName
        DispatchQueue.main.async { self.judge(preview) }
    }

    private func isBlockingEnforced() -> Bool {
        if currentRunningFocusType["isRelaxFocus"] as? Bool ?? false {
            return false
        }
        return isFocusModeOn() || customBlockingScheduleManagerObj.isAnyCustomScheduleOn || isAnyAllowedFocusModeActivityRunning
    }

    // MARK: - Verdict

    private func judge(_ preview: QuickLookPreview) {
        let fileName = preview.fileName
        let defaultApp = defaultApplication(forFileNamed: fileName, fileURL: preview.fileURL)
        let defaultAppNameLowercased = defaultApp?.deletingPathExtension().lastPathComponent.lowercased() ?? ""
        addLog(text: "quickLookPreviewMonitor: preview of '\(fileName)' opens with '\(defaultAppNameLowercased)'")

        switch verdict(forDefaultAppNameLowercased: defaultAppNameLowercased) {
        case .allowed:
            addLog(text: "quickLookPreviewMonitor: '\(fileName)' allowed — its app is allowed by the block list")
        case .blocked:
            addLog(text: "quickLookPreviewMonitor: '\(fileName)' blocked — its app is blocked by the block list")
            focusBlockUnwantedApp(runningApp: preview.service, appName: fileName, showNotification: true, isAppBlockByAi: false)
        case .needsRelevanceCheck:
            guard SettingsManagerObject.isAIBlockingEnabled() else {
                addLog(text: "quickLookPreviewMonitor: '\(fileName)' blocked — its app isn't on the allow list and AI blocking is off")
                focusBlockUnwantedApp(runningApp: preview.service, appName: fileName, showNotification: true, isAppBlockByAi: false)
                return
            }
            // Reuse only a response bound to the current task/content, never score history.
            tryCheckAppFromAi(appName: fileName, runningApp: preview.service)
        }
    }

    /// Same order `AppDelegate.frontApplicationChanged` classifies a frontmost app in, applied to the app
    /// the previewed file opens with: always-allowed wins, then the block list's explicit blocks, then
    /// its allows. A file with no default app has nothing to vouch for it and goes to the AI check.
    private func verdict(forDefaultAppNameLowercased appName: String) -> QuickLookVerdict {
        if appName.isEmpty {
            return .needsRelevanceCheck
        }
        if appName == selfAppName.lowercased() || focusDefaultAllowApps.contains(appName) {
            return .allowed
        }
        if SettingsManagerObject.effectiveAlwaysAllowedApps.contains(where: { appBaseNameLowercased(path: $0) == appName }) {
            return .allowed
        }
        let blockedAppPaths = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
        if blockedAppPaths.contains(where: { appBaseNameLowercased(path: $0) == appName }) {
            return .blocked
        }
        if currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false {
            return .allowed
        }
        let allowedAppPaths = currentRunningFocusType["allowed_apps"] as? [String] ?? []
        if isRunningAppInAllowedApps(allowedAppPaths, runningAppNameLowercased: appName) {
            return .allowed
        }
        if currentRunningFocusType["isDefault"] as? Bool ?? false {
            return .allowed
        }
        return .needsRelevanceCheck
    }

    private func appBaseNameLowercased(path: String) -> String {
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent.lowercased()
    }

    // MARK: - Default app for the file

    private func defaultApplication(forFileNamed fileName: String, fileURL: URL?) -> URL? {
        if let fileURL = fileURL, let appURL = NSWorkspace.shared.urlForApplication(toOpen: fileURL) {
            return appURL
        }
        guard let type = contentType(forFileNamed: fileName) else { return nil }
        if #available(macOS 12.0, *) {
            return NSWorkspace.shared.urlForApplication(toOpen: type)
        }
        return LSCopyDefaultApplicationURLForContentType(type.identifier as CFString, .all, nil)?.takeRetainedValue() as URL?
    }

    private func contentType(forFileNamed fileName: String) -> UTType? {
        let fileExtension = (fileName as NSString).pathExtension
        guard !fileExtension.isEmpty else { return nil }
        return UTType(filenameExtension: fileExtension)
    }

    /// Context line handed to the AI relevance check so it judges the FILE (name + type + the app it
    /// opens with), not the meaningless "QuickLookUIService" process name.
    func aiContext(forFileNamed fileName: String) -> String {
        let typeDescription = contentType(forFileNamed: fileName)?.localizedDescription ?? (fileName as NSString).pathExtension
        var context = "The user is viewing a Quick Look preview of the file \"\(fileName)\" (\(typeDescription))"
        if let appURL = defaultApplication(forFileNamed: fileName, fileURL: nil) {
            context += ", which opens with \(appURL.deletingPathExtension().lastPathComponent)"
        }
        return context + "."
    }

    // MARK: - Finding open previews

    /// Quick Look is an XPC service: its host (often Finder) remains frontmost. Verify the actual
    /// preview instead of requiring the service to become the foreground app.
    func isPreviewOpen(fileName: String, service: NSRunningApplication) -> Bool {
        openPreviews(in: service).contains { $0.fileName == fileName }
    }

    private func openPreviews() -> [QuickLookPreview] {
        return NSWorkspace.shared.runningApplications.filter(isQuickLookService).flatMap(openPreviews(in:))
    }

    /// Accessibility is the only source: the preview panel's title is the file name, and `kCGWindowName`
    /// would need Screen Recording permission the app doesn't have. Accessibility permission is already
    /// required for blocking.
    private func openPreviews(in service: NSRunningApplication) -> [QuickLookPreview] {
        let appElement = AXUIElementCreateApplication(service.processIdentifier)
        AXUIElementSetMessagingTimeout(appElement, axMessagingTimeoutSeconds)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return [] }
        return windows.compactMap { preview(from: $0, in: service) }
    }

    /// The service also hosts Finder's embedded preview pane (gallery / column view) as a remote view; only
    /// a real preview panel — a titled window with a close button — counts as a Quick Look preview.
    private func preview(from window: AXUIElement, in service: NSRunningApplication) -> QuickLookPreview? {
        guard let title = stringAttribute(kAXTitleAttribute, of: window), !title.isEmpty,
              closeButton(of: window) != nil else { return nil }
        let fileURL = stringAttribute(kAXDocumentAttribute, of: window).flatMap { URL(string: $0) }
        return QuickLookPreview(fileName: title, fileURL: fileURL, service: service, window: window)
    }

    private func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef) == .success else { return nil }
        return (valueRef as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func closeButton(of window: AXUIElement) -> AXUIElement? {
        var buttonRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &buttonRef) == .success,
              let button = buttonRef else { return nil }
        return (button as! AXUIElement)
    }

    // MARK: - Closing a blocked preview

    /// The Quick Look counterpart of hiding a blocked app: press each preview window's close button, and
    /// if a preview is still up shortly after, kill the service (Finder respawns it on the next preview).
    func closePreviews(hostedBy service: NSRunningApplication) {
        queue.async {
            for preview in self.openPreviews(in: service) {
                self.pressCloseButton(of: preview)
            }
            self.queue.asyncAfter(deadline: .now() + self.closeVerifyDelaySeconds) {
                guard !self.openPreviews(in: service).isEmpty else { return }
                addLog(text: "quickLookPreviewMonitor: preview still open after close — force-terminating QuickLookUIService")
                DispatchQueue.main.async { _ = service.forceTerminate() }
            }
        }
    }

    private func pressCloseButton(of preview: QuickLookPreview) {
        guard let button = closeButton(of: preview.window) else { return }
        let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
        addLog(text: "quickLookPreviewMonitor: pressed close on '\(preview.fileName)' → \(result.rawValue)")
    }
}
