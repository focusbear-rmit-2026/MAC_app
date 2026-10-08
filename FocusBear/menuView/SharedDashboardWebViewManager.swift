//
//  SharedDashboardWebViewManager.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

/// The dashboard.focusbear.io screens this manager can show. A WKWebView renders one URL at a
/// time, so "preload at startup" + "share one webview" together mean: one screen (whichever is
/// preloaded) is warm and near-instant on first open; the other two still do a full navigation
/// on first visit (same as today), but reuse the same already-warm WKWebView process/cookies
/// rather than paying for a brand new WKWebView + VC instantiation.
enum DashboardScreen: Equatable, Hashable {
    case todoList
    case editHabits
    case stats

    /// The URL for this screen, minus the cache-busting query param — SharedDashboardWebViewManager
    /// appends that separately, memoized per screen per app launch (see bustCacheId(for:)).
    var baseUrlString: String {
        switch self {
        case .todoList:
            return "https://dashboard.focusbear.io/webview/tools-todo-list"
        case .editHabits:
            var settingUrl = "https://dashboard.focusbear.io"
            if let settings = configjson.value(forKey: "settings") as? NSDictionary,
               let url = settings.value(forKey: "settingUrlNew") as? String {
                settingUrl = url
            }
            return "\(settingUrl)/webview/settings"
        case .stats:
            return "https://dashboard.focusbear.io/webview/stats"
        }
    }

    /// Short, path-independent screen token exchanged with the dashboard SPA — the value passed to
    /// `window.fbNavigate(...)` and matched against the `screen` field of a `webview_ready` post.
    /// Mirrors the web `WEBVIEW_SCREEN` enum (web_dashboard `src/enums/bridge.ts`); keep in sync.
    var webviewScreenToken: String {
        switch self {
        case .todoList: return "todo"
        case .editHabits: return "settings"
        case .stats: return "stats"
        }
    }
}

/// The web ⇄ Mac readiness/navigation bridge, mirroring web_dashboard `src/enums/bridge.ts`
/// (`MAC_MESSAGE_HANDLER`, `WEBVIEW_READY_STATUS`, `WEBVIEW_READY_ERROR_REASON`). The SPA posts one
/// terminal `{ screen, status, reason? }` per screen presentation to the `webview_ready` handler;
/// the Mac drives client-side tool switching by calling `window.fbNavigate('<token>')`. Contract:
/// web_dashboard `plans/webview-mac-shared-webview-contract.md` (PR #3701).
private enum WebviewReadyBridge {
    static let handlerName = "webview_ready"
    static let navigateFunction = "fbNavigate"

    static let screenKey = "screen"
    static let statusKey = "status"
    static let reasonKey = "reason"

    static let statusReady = "ready"
    static let statusError = "error"

    /// No READY within this window ⇒ treat the screen as hung (blank/broken, web_dashboard #3376):
    /// reload the bundle once, then show the failure overlay. Sits above the web's 10s token-timeout
    /// so the page's own `status:"error"` post normally arrives first and we react to it immediately.
    static let watchdogSeconds: TimeInterval = 12
}

/// One shared WKWebView for the Todo List / Edit Habits / Stats sidebar tools, instead of each
/// owning its own persistent instance. Reparented into whichever tool's container view is
/// currently shown; always re-navigates on `present` (matching this app's existing
/// reload-on-every-open behaviour for these screens) except for the one-time startup `preload`.
final class SharedDashboardWebViewManager: NSObject {
    static let shared = SharedDashboardWebViewManager()

    let webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private(set) var currentScreen: DashboardScreen?
    private var didConfigure = false
    private var webViewLoadFailedVcObj: webViewLoadFailedVc?

    /// True once the ~5.7 MB SPA bundle has loaded at least once this session. When warm, screen
    /// switches go through client-side routing (`window.fbNavigate`) instead of a full
    /// `webView.load()`, so the bundle isn't re-booted on every sidebar click.
    private var bundleDidLoad = false
    /// Set when the last full navigation errored, so the next `present` forces a fresh bundle load
    /// rather than trying to `fbNavigate` inside a page that never came up.
    private var lastLoadFailed = false
    /// Guards the watchdog's one-shot recovery: the first missed READY reloads the bundle, a second
    /// miss shows the failure overlay instead of reloading forever. Reset on each user-initiated present.
    private var reloadAttempted = false
    /// Fires if no `status:"ready"` arrives within `watchdogSeconds` of a presentation (blank-hang guard).
    private var readyWatchdog: Timer?
    /// Screens that posted `status:"ready"` since the last full bundle load. The SPA posts READY once
    /// per screen presentation and `fbNavigate` to the screen that is ALREADY mounted is a no-op that
    /// never re-posts it, so a re-present of the current screen must be satisfied from this set.
    private var readyScreens: Set<DashboardScreen> = []
    /// Set while the very first (startup) load is in flight and not yet READY.
    private var isPreloading = false

    /// One cache-busting id per screen, generated once on first navigation and reused for the rest
    /// of the app's run — busts a stale bundle once per launch (e.g. after a Focus Bear or dashboard
    /// update) without re-busting it on every single switch back to a screen already visited this
    /// session, so WKWebView's own HTTP cache can serve repeat navigations to the same screen fast.
    private var bustCacheIdsByScreen: [DashboardScreen: String] = [:]

    // Shown while any screen is loading, mirroring the per-screen spinners todoListToolVc/setUpVc
    // used to have — centralised here since they now share one webview.
    private let loadingSpinner: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .regular
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private override init() {
        super.init()
    }

    private func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true

        webView.navigationDelegate = self
        webView.configuration.userContentController.add(AccessTokenRequestHandler.shared, name: AccessTokenRequestHandler.messageName)

        // Readiness handshake from the SPA (web_dashboard PR #3701): one terminal
        // { screen, status, reason? } post per screen presentation. Retain cycle here is
        // intentional — this manager is a never-deallocated singleton (as is AccessTokenRequestHandler).
        webView.configuration.userContentController.add(self, name: WebviewReadyBridge.handlerName)

        // Edit Habits' settings-save flow (selectJsonVc) and Stats' external-link handlers
        // (setUpVc) — both previously registered on their own now-unused per-screen webview.
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "setting_saved")
        webView.configuration.userContentController.add(handler, name: "open_marketplace")
        webView.configuration.userContentController.add(handler, name: "detect_user_settings_change")
        webView.configuration.userContentController.add(handler, name: "open_android_app")
        webView.configuration.userContentController.add(handler, name: "open_ios_app")
        webView.configuration.userContentController.add(handler, name: "download_focus_summaries")

        webView.addSubview(loadingSpinner)
        NSLayoutConstraint.activate([
            loadingSpinner.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])
    }

    /// Preloads a screen without attaching the webview to any visible container — called once at
    /// startup so the first sidebar click is already warm.
    func preload(_ screen: DashboardScreen) {
        configureIfNeeded()
        isPreloading = true
        beginPresentation(of: screen)
    }

    /// Shows `screen`, reparenting the shared webview into `containerView` (filling it). The first
    /// visit does a full bundle load; once warm, later switches route client-side via `fbNavigate`
    /// (no ~5.7 MB re-boot) — see `switchTo`.
    func present(_ screen: DashboardScreen, in containerView: NSView) {
        configureIfNeeded()
        webView.removeFromSuperview()
        containerView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        beginPresentation(of: screen)
    }

    /// A user-initiated presentation — resets the one-shot reload guard, then switches.
    private func beginPresentation(of screen: DashboardScreen) {
        reloadAttempted = false
        switchTo(screen)
    }

    /// Switches to `screen`: client-side via `fbNavigate` when the bundle is already warm, otherwise
    /// a full load. Either way arms the readiness watchdog and waits for the SPA's `status:"ready"`.
    private func switchTo(_ screen: DashboardScreen) {
        let previousScreen = currentScreen
        currentScreen = screen
        loadingSpinner.startAnimation(nil)
        armReadyWatchdog()
        guard bundleDidLoad, !lastLoadFailed else {
            loadBundle(for: screen)
            return
        }
        // Warm path: inject the next screen's token/data FIRST, then navigate client-side, so the
        // freshly-mounted screen re-runs init against an already-present token (contract ordering,
        // avoids a blank frame). No `didFinish` fires for client-side nav, hence injecting here.
        loadCurrentScreenData()
        guard previousScreen == screen else {
            callWhenReady(WebviewReadyBridge.navigateFunction, with: "'\(screen.webviewScreenToken)'")
            return
        }
        // Re-presenting the screen the SPA is already on: `fbNavigate` to the current route is a no-op
        // that never re-posts READY (verified against the deployed bundle), so the watchdog would fire
        // and reload the whole ~5.7 MB bundle — the ~15 s "reload" on every first open after launch.
        // If this screen already reported READY it is interactive now; otherwise its READY is still on
        // its way (a page loaded off-window only posts it once the webview is attached — see
        // armReadyWatchdog), so keep waiting for that instead of navigating.
        if readyScreens.contains(screen) {
            handleWebviewReady()
        }
    }

    /// Full `webView.load()` of the bundle for `screen` — the cold-start path and the watchdog/manual
    /// reload recovery. Token/data injection then happens in `didFinish navigation`.
    private func loadBundle(for screen: DashboardScreen) {
        currentScreen = screen
        lastLoadFailed = false
        loadingSpinner.startAnimation(nil)
        readyScreens.removeAll()
        armReadyWatchdog()
        guard let url = url(for: screen) else { return }
        webView.load(URLRequest(url: url))
    }

    private func url(for screen: DashboardScreen) -> URL? {
        let bustCacheId = bustCacheIdsByScreen[screen] ?? {
            let id = getUuid()
            bustCacheIdsByScreen[screen] = id
            return id
        }()
        var urlString = "\(screen.baseUrlString)?bust_cache=\(bustCacheId)"
        if screen == .editHabits {
            urlString += "&device_id=\(currentDeviceId)"
        }
        return URL(string: urlString)
    }

    // MARK: - Per-screen token/settings injection (ported from todoListToolVc / selectJsonVc / setUpVc)

    private func loadCurrentScreenData(requestId: String? = nil) {
        switch currentScreen {
        case .todoList: loadTodoListToken(requestId: requestId)
        case .editHabits: loadEditHabitsSettings(requestId: requestId)
        case .stats: loadStatsToken(requestId: requestId)
        case nil: break
        }
    }

    /// Called by AccessTokenRequestHandler when the web page requests a refreshed token.
    func reinjectCurrentScreenToken(requestId: String) {
        loadCurrentScreenData(requestId: requestId)
    }

    /// Waits (via a short JS-side polling loop) for `functionName` to be defined on the page before
    /// calling it with `argsJson` — the dashboard SPA takes an unpredictable moment after
    /// `didFinish navigation` to register these window-level functions. Polling for the exact
    /// function precisely, rather than guessing a fixed delay before injecting, is both more
    /// correct (no race if the page is slow) and faster (no wasted wait if the page is already
    /// ready) than the flat `sleep(1)` this used to sit behind in `didFinish navigation`.
    private func callWhenReady(_ functionName: String, with argsJson: String) {
        let script = "let waitFor_\(functionName) = setInterval(() => { if (window.\(functionName)) { \(functionName)(\(argsJson)); clearInterval(waitFor_\(functionName)); } }, 100);"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func loadTodoListToken(requestId: String?) {
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let intention = whatToAchieveInFocusBlock
        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\"}"
        if !intention.isEmpty {
            stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\",\"intention\":\"\(intention)\"}"
        }
        if let requestId = requestId {
            stringJson = String(stringJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        callWhenReady("loadAccessTokenForToDo", with: stringJson)
    }

    private func loadStatsToken(requestId: String?) {
        let theme = getWindowTheme()
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var stringJson = "{\"access_token\":\"\(appdelegate!.credential?.accessToken ?? "")\",\"type\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\"}"
        if let requestId = requestId {
            stringJson = String(stringJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        callWhenReady("loadAccessTokenForStats", with: stringJson)
    }

    private func loadEditHabitsSettings(requestId: String?) {
        let theme = getWindowTheme()
        var flags = "[\"settings-updated\"]"
        if SettingsManagerObject.isGeekModeEnabled {
            flags = "[\"settings-updated\",\"geek-mode\",\"save-settings-migrate-to-web\"]"
        } else {
            flags = "[\"settings-updated\",\"simple-mode\",\"save-settings-migrate-to-web\"]"
        }
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let accessToken = appdelegate!.credential?.accessToken ?? ""
        var settingsJson = "{\"access_token\":\"\(accessToken)\",\"platform\":\"mac\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\",\"flags\":\(flags)}"
        if let requestId = requestId {
            settingsJson = String(settingsJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        callWhenReady("loadSettingsData", with: settingsJson)

        var arrInstalledApps = [String]()
        let urls = FileManager.default.urls(for: .applicationDirectory, in: [.systemDomainMask, .localDomainMask])
        let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey, URLResourceKey.nameKey]
        for url in urls {
            guard let array = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options: .skipsHiddenFiles) else { continue }
            for appUrl in array {
                if appUrl.pathExtension == "app" {
                    arrInstalledApps.append(appUrl.deletingPathExtension().lastPathComponent)
                } else if appUrl.isDirectory {
                    if let arrAppInFolder = try? FileManager.default.contentsOfDirectory(at: appUrl, includingPropertiesForKeys: properties, options: .skipsHiddenFiles) {
                        for appUrl in arrAppInFolder where appUrl.pathExtension == "app" {
                            arrInstalledApps.append(appUrl.deletingPathExtension().lastPathComponent)
                        }
                    }
                }
            }
        }
        addLog(text: "Load Installed Apps to web settings:- \(arrInstalledApps)")
        if let data = try? JSONSerialization.data(withJSONObject: ["installedApps": arrInstalledApps], options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            callWhenReady("LoadInstalledApps", with: str)
        }

        var arrFocusNames = [[String: String]]()
        for i in 0..<arrFocusType.count {
            if let name = arrFocusType[i]["name"] as? String {
                arrFocusNames.append(["id": arrFocusType[i]["id"] as? String ?? "", "name": name])
            }
        }
        if let data = try? JSONSerialization.data(withJSONObject: ["focusNames": arrFocusNames], options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            callWhenReady("LoadFocusNames", with: str)
        }
    }
}

// MARK: - Readiness watchdog + recovery

extension SharedDashboardWebViewManager {
    /// (Re)starts the "no READY within `watchdogSeconds`" timer for the current presentation.
    private func armReadyWatchdog() {
        readyWatchdog?.invalidate()
        // A webview with no window (the startup preload) loads and runs the SPA, but WebKit holds the
        // page's READY post until the view is attached and visible — nobody is waiting on it yet, so a
        // watchdog here only ever fires, reloads the bundle for nothing, burns the one-shot retry and
        // ends in the failure overlay. `present` re-arms it once the view is on screen.
        guard webView.window != nil else {
            readyWatchdog = nil
            return
        }
        readyWatchdog = Timer.scheduledTimer(withTimeInterval: WebviewReadyBridge.watchdogSeconds, repeats: false) { [weak self] _ in
            self?.handleWebviewNotReady(reason: "watchdog-timeout")
        }
    }

    private func cancelReadyWatchdog() {
        readyWatchdog?.invalidate()
        readyWatchdog = nil
    }

    /// The SPA reported the current screen is interactive — clear the loading/error UI.
    private func handleWebviewReady() {
        cancelReadyWatchdog()
        reloadAttempted = false
        isPreloading = false
        if let screen = currentScreen {
            readyScreens.insert(screen)
            addLog(text: "Shared dashboard webview ready for \(screen.webviewScreenToken)")
        }
        loadingSpinner.stopAnimation(nil)
        removeWebViewLoadFailedView(webView: webView)
    }

    /// The current screen is hung or reported an error: reload the bundle once, then (on a second
    /// miss) show the failure overlay rather than reloading forever.
    private func handleWebviewNotReady(reason: String) {
        cancelReadyWatchdog()
        guard let screen = currentScreen else { return }
        addLog(text: "Shared dashboard webview not ready (\(reason)) for \(screen.webviewScreenToken)")
        if reloadAttempted {
            handleLoadError(webView: webView)
        } else {
            reloadAttempted = true
            loadBundle(for: screen)
        }
    }
}

extension SharedDashboardWebViewManager: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == WebviewReadyBridge.handlerName,
              let body = message.body as? [String: Any],
              let status = body[WebviewReadyBridge.statusKey] as? String else { return }
        // Ignore terminal posts for a screen we're no longer showing (e.g. a late signal after the
        // user already switched tools) so a stale error can't tear down the current screen.
        let screenToken = body[WebviewReadyBridge.screenKey] as? String
        guard screenToken == currentScreen?.webviewScreenToken else { return }

        switch status {
        case WebviewReadyBridge.statusReady:
            handleWebviewReady()
        case WebviewReadyBridge.statusError:
            let reason = body[WebviewReadyBridge.reasonKey] as? String ?? "unspecified"
            handleWebviewNotReady(reason: "web-error:\(reason)")
        default:
            break
        }
    }
}

extension SharedDashboardWebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // HTML/bundle finished loading. We deliberately keep the spinner and watchdog running until
        // the SPA posts status:"ready" — a completed navigation doesn't mean the screen is actually
        // interactive (the token still has to land), and a blank-hang after didFinish is exactly the
        // failure #3376 is about. Each injector polls for its own window.<fn> (callWhenReady).
        bundleDidLoad = true
        lastLoadFailed = false
        removeWebViewLoadFailedView(webView: webView)
        loadCurrentScreenData()
        if currentScreen == .editHabits {
            allApiObject.capturePosthog(event: "edit-habits", metadata: [:])
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        lastLoadFailed = true
        handleLoadError(webView: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        lastLoadFailed = true
        handleLoadError(webView: webView)
    }

    private func removeWebViewLoadFailedView(webView: WKWebView) {
        if let vc = webViewLoadFailedVcObj, webView.subviews.contains(vc.view) {
            vc.view.removeFromSuperview()
        }
    }

    private func handleLoadError(webView: WKWebView) {
        cancelReadyWatchdog()
        loadingSpinner.stopAnimation(nil)
        if let vc = webViewLoadFailedVcObj, webView.subviews.contains(vc.view) {
            vc.reloadData()
            return
        }
        let vc = getWebViewLoadFailedVcObject()
        vc.customDelegate = self
        vc.webView = webView
        webView.addSubview(vc.view)
        webView.addConstraints(subView: vc.view)
        vc.reloadData()
        webViewLoadFailedVcObj = vc
    }
}

extension SharedDashboardWebViewManager: webViewLoadFailedDelegate {
    func reloadClicked(webView: WKWebView) {
        guard let screen = currentScreen else { return }
        reloadAttempted = false
        loadBundle(for: screen)
    }
}
