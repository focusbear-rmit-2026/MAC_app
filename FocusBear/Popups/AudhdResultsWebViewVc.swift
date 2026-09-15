//
//  AudhdResultsWebViewVc.swift
//  Focus Bear
//
//  Full-screen WKWebView that unlocks the gated "advanced AuDHD results" in-app.
//  Reached via the `focusbear://view-audhd-results?test-code=<CODE>` deep link
//  (see AppDelegate.filterUrl). Part of Focus-Bear/online-tests#57 (Phase 2 — Mac).
//

import Cocoa
import WebKit

/// Named constants for the AuDHD results deep link + results URL, so there are no
/// magic strings scattered across the deep-link handler and this view controller.
enum AudhdResults {
    /// Custom-scheme prefix that triggers the in-app results webview.
    static let deepLinkPrefix = "focusbear://view-audhd-results?"
    /// Query-param key carrying the participant's retest / test code.
    static let testCodeParamKey = "test-code"

    /// Base domain the gated results page is served from. This is the Cloudflare Pages host the online
    /// AuDHD test runs on — the results page + its Worker API (`/api/advanced-results`) live here, so the
    /// webview must load THIS domain (online-tests#57). `www.focusbear.io/tests/view-results` 404s.
    static let baseDomain = "https://audhdtest-focusbear.pages.dev"
    /// Path (under `baseDomain`) of the gated advanced-results page. NOTE: `/view-results` (200), NOT
    /// `/view-audhd-results` — the latter is only the custom-scheme deep-link path and 404s as a web URL.
    static let resultsPath = "/view-results"

    /// Case-sensitive marker the results Worker requires in the webview's User-Agent to serve the gated
    /// profile — without it `/api/advanced-results` returns 403 and the page shows "Open in the app"
    /// (online-tests#57). Same marker the mobile app uses.
    static let userAgentAppMarker = "FocusBearApp"

    /// Analytics event names for the AuDHD results popup. Centralised here (not inline) so every platform —
    /// Mac / Windows / mobile — fires the SAME event strings. Do NOT rename the values; that breaks event
    /// history. Add new audhd-test event names here too.
    static let resultsShownEvent = "audhd-results-window-shown"
    static let resultsClosedEvent = "audhd-results-window-closed"

    /// Builds the full results URL for a given test code, url-encoding the value.
    static func resultsURL(testCode: String) -> URL? {
        let encodedCode = testCode.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? testCode
        return URL(string: "\(baseDomain)\(resultsPath)?\(testCodeParamKey)=\(encodedCode)")
    }

    /// Extracts the (url-decoded) `test-code` value from a full deep-link URL such as
    /// `focusbear://view-audhd-results?test-code=BEAR-1234[&other=…]`. Tolerates the
    /// param appearing anywhere among `&`-separated params. Returns nil if absent.
    static func testCode(fromDeepLink deepLink: String) -> String? {
        guard deepLink.hasPrefix(deepLinkPrefix) else { return nil }
        let query = String(deepLink.dropFirst(deepLinkPrefix.count))
        for pair in query.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            guard parts.count >= 2, parts[0] == testCodeParamKey else { continue }
            let rawValue = parts[1...].joined(separator: "=")
            return rawValue.removingPercentEncoding ?? rawValue
        }
        return nil
    }

    /// UserDefaults flag so the deferred-deep-link clipboard is read exactly once,
    /// on the first launch after install — never re-scanned on later launches.
    static let clipboardCheckedDefaultsKey = "audhd_clipboard_checked"

    /// Extracts a Focus Bear retest code from a clipboard string. A fresh install
    /// coming from the web AuDHD test carries the code on the clipboard (the deep
    /// link itself is lost across the install — see online-tests deferred-link
    /// work), so this recovers it. Matches the `BEAR-XXXXX-XXXXX` code format
    /// (also the shorter v1 `BEAR-XXXX`). Returns nil if the clipboard holds no code.
    static func testCode(fromClipboard clip: String) -> String? {
        guard let range = clip.range(
            of: "BEAR-[A-Z0-9]+(-[A-Z0-9]+)?",
            options: [.regularExpression, .caseInsensitive]
        ) else { return nil }
        return String(clip[range])
    }
}

private extension CharacterSet {
    /// Query-value-safe set: the standard query set minus the sub-delimiters that
    /// carry structural meaning in a query string.
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=?+")
        return set
    }()
}

/// Code-only view controller hosting a full-size WKWebView with no URL bar.
/// Modelled on `surveyVc` but without the storyboard outlet / access-token handshake,
/// since the results page is a plain external URL.
final class AudhdResultsWebViewVc: NSViewController, WKNavigationDelegate, NSWindowDelegate {

    private var testCode: String = ""
    /// Fired once, right after `resultsClosedEvent`, when the user closes this window. Used to defer
    /// showing onboarding (or anything else) on a fresh install until after the user has seen their
    /// gated results — see `showAudhdResultsWindow(testCode:onClose:)`.
    var onClose: (() -> Void)?

    private lazy var webView: WKWebView = {
        // applicationNameForUserAgent APPENDS the marker to the default WebKit User-Agent (keeping a
        // valid browser UA), and it rides both the page load AND its subresource fetches — which is
        // exactly what the results Worker checks, so the gated `/api/advanced-results` returns 200
        // instead of 403. Must be set on the configuration before the webView is created.
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = AudhdResults.userAgentAppMarker
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    override func loadView() {
        // Provide a container view; the webView fills it edge-to-edge (no chrome).
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1024, height: 768))
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadResults()
    }

    /// Sets the test code and (re)loads the results page. Safe to call before the
    /// view is loaded — `viewDidLoad` will trigger the initial load.
    func present(testCode: String) {
        self.testCode = testCode
        if isViewLoaded {
            loadResults()
        }
    }

    private func loadResults() {
        guard let url = AudhdResults.resultsURL(testCode: testCode) else {
            addLog(text: "AudhdResultsWebViewVc: could not build results URL for code")
            return
        }
        addLog(text: "AudhdResultsWebViewVc: loading advanced AuDHD results")
        webView.load(URLRequest(url: url))
    }

    // MARK: - NSWindowDelegate

    /// Fired when the user closes the results popup (title-bar ✕). Mirrors `resultsShownEvent` fired when
    /// it opens, so the two can be paired in analytics. The window sets this VC as its delegate in
    /// `showAudhdResultsWindow`.
    func windowWillClose(_ notification: Notification) {
        addLog(text: "AudhdResultsWebViewVc: results window closed")
        allApiObject.capturePosthog(event: AudhdResults.resultsClosedEvent, metadata: [:])
        let callback = onClose
        onClose = nil // one-shot: this VC/window are reused across calls (isReleasedWhenClosed = false)
        callback?()
    }
}
