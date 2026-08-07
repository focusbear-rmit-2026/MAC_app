//
//  brainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class brainDumpVc: NSViewController, NSTextViewDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var boxBrainDumpWebView: NSBox!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnSave: Button!
    // #2142: legacy "old brain dump" UI. All users are now moved to the webview Brain Dump and there's no
    // way back, so these are kept only for storyboard compatibility and are always hidden.
    @IBOutlet weak var btnTryNewBrainDump: Button!
    @IBOutlet weak var btnToggleOldVersion: underLineButton!
    @IBOutlet weak var stackViewOldNotes: NSStackView!
    @IBOutlet weak var scrollViewOldNotes: NSScrollView!
    @IBOutlet var textViewOldNotes: NSTextView!

    // Ensures the app metadata is handed to the webview only once per fresh page load, so in-page
    // navigations don't re-send it.
    private var hasSentAppMetaData = false

    override func viewDidLoad() {
        super.viewDidLoad()
        btnSave.title = "Close"
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary {
            btnSave.title = brainDumpVcInfo.value(forKey: "buttonCloseText") as? String ?? btnSave.title
        }

        let webViewConfiguration = WKWebViewConfiguration()
        let newWebView = WKWebView(frame: CGRect.zero, configuration: webViewConfiguration)
        let userAgent = newWebView.stringByEvaluatingJavaScript(from: "navigator.userAgent")! + " Version/15.2 Safari/605.1.15"

        webView.customUserAgent = userAgent
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        webView.isHidden = true // hidden until explicitly shown
        textViewOldNotes.delegate = self
    }

    override func viewWillAppear() {
        resetData()
    }

    func resetData() {
        // #2142: everyone is on the webview Brain Dump now — the old local-notes editor and the
        // switch-back option are gone, so always show the webview.
        boxBrainDumpWebView.isHidden = false
        stackViewOldNotes.isHidden = true
        btnTryNewBrainDump.isHidden = true
        btnToggleOldVersion.isHidden = true
        webView.isHidden = false
        loadWebView()
    }

    func loadWebView() {
        // ?open=braindump lands the webview directly in the Brain Dump section (web_dashboard #3624).
        let urlString = "https://dashboard.focusbear.io/webview/notes?open=braindump"
        if let link = URL(string: urlString) {
            // Reset the one-shot guard so the metadata is handed off once for this fresh page load.
            hasSentAppMetaData = false
            let request = URLRequest(url: link)
            self.webView.load(request)
        }
    }

    func focusModeFinished(){
        loadWebView()
    }

    func breakStarted(){
        //        lblTitleWorkNote.stringValue = titleWorkNoteSecond
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        if textView == textViewOldNotes {
            UserDefaults.standard.set(textViewOldNotes.string, forKey: kUserdefaultsFocusModeNotes)
        }
    }

    // #2142: the legacy try-new / switch-back buttons are always hidden now; kept only so the
    // storyboard's action connections resolve.
    @IBAction func btnTryNewBrainDumpClicked(_ sender: Any) { }

    @IBAction func btnToggleOldVersionClicked(_ sender: Any) { }

    @IBAction func btnSaveClicked(_ sender: Any) {
        self.view.window?.close()
    }

    func reloadClicked(webView:WKWebView){
        loadWebView()
    }

    var webViewLoadFailedVcObj:webViewLoadFailedVc?
    func removeWebViewLoadFailedView(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.view.removeFromSuperview()
            }
        }
    }
    func handleLoadError(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.reloadData()
                return;
            }
        }
        webViewLoadFailedVcObj = getWebViewLoadFailedVcObject()
        webViewLoadFailedVcObj!.customDelegate = self
        webViewLoadFailedVcObj?.webView = webView
        webView.addSubview(webViewLoadFailedVcObj!.view)
        webView.addConstraints(subView: webViewLoadFailedVcObj!.view)
        webViewLoadFailedVcObj?.reloadData()
    }
}


extension brainDumpVc: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        // A load succeeded → clear any "load failed" overlay left from an earlier failure/retry.
        removeWebViewLoadFailedView(webView: webView)

        // Hand the webview its metadata once per fresh load (loadWebView resets the flag), so in-page
        // navigations don't re-send.
        guard !hasSentAppMetaData else { return }
        hasSentAppMetaData = true
        sendAppMetaDataToWebView(webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
}

extension brainDumpVc {
    /// #2142: hand the notes webview its metadata (token + theme). Token-only: the web app loads the
    /// brain dump from the API after auth. The saved local brain dump is migrated to the backend once at
    /// startup (AppDelegate.checkWindowState → migrateBrainDumpToBackendIfNeeded), so by the time this
    /// webview opens the API already has it — no re-seed needed here.
    ///
    /// The bridge is only registered after React mount/hydration, so poll (bounded) from the native side
    /// until it exists.
    private func sendAppMetaDataToWebView(_ webView: WKWebView) {
        let meta: [String: Any] = [
            "access_token": appdelegate!.credential?.accessToken ?? "",
            "platform": "mac",
            // theme is a shared field — always send it, on every open.
            "theme": getWindowTheme()
        ]
        // JSON-serialize so newlines/quotes are delivered safely.
        guard let data = try? JSONSerialization.data(withJSONObject: meta),
              let payload = String(data: data, encoding: .utf8) else { return }
        // Returns true only when the bridge exists and was called; false means "not ready yet".
        let js = """
        (function() {
          if (typeof window.initAppMetaData === 'function') {
            window.initAppMetaData(\(payload));
            return true;
          }
          return false;
        })();
        """
        var attemptsLeft = 40   // ~4s total at 100ms spacing
        func attempt() {
            webView.evaluateJavaScript(js) { result, _ in
                if (result as? Bool) != true, attemptsLeft > 0 {
                    attemptsLeft -= 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: attempt)
                }
            }
        }
        attempt()
    }
}
