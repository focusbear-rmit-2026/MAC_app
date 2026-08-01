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
    @IBOutlet weak var btnTryNewBrainDump: Button!
    @IBOutlet weak var btnToggleOldVersion: underLineButton!
    @IBOutlet weak var stackViewOldNotes: NSStackView!
    @IBOutlet weak var scrollViewOldNotes: NSScrollView!
    @IBOutlet var textViewOldNotes: NSTextView!
    
    // Tracks whether the user has chosen to stay on the old local notes version
    var isShowingOldVersion: Bool {
        get { UserDefaults.standard.bool(forKey: "kUserDefaultsBrainDumpShowOldVersion") }
        set { UserDefaults.standard.set(newValue, forKey: "kUserDefaultsBrainDumpShowOldVersion") }
    }
    
    var hasEverSwitchedToWebview: Bool {
        get { UserDefaults.standard.bool(forKey: "kUserDefaultsBrainDumpEverSwitchedToWebview") }
        set { UserDefaults.standard.set(newValue, forKey: "kUserDefaultsBrainDumpEverSwitchedToWebview") }
    }

    // Ensures the initial brain-dump content is injected only once per load,
    // so subsequent in-page navigations don't clobber user-typed webview notes.
    private var hasInjectedInitialBrainDump = false
    
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
        let existingNotes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        let hasOldContent = !existingNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isShowingOldVersion {
            // User explicitly toggled back to old version
            // Always show Try button so user is never stuck with no path to webview
            boxBrainDumpWebView.isHidden = true
            stackViewOldNotes.isHidden = false
            textViewOldNotes.string = existingNotes
            btnTryNewBrainDump.isHidden = false
            btnToggleOldVersion.isHidden = true
            webView.isHidden = true
        } else if hasEverSwitchedToWebview || !hasOldContent {
            // User already switched to webview before, or has no old notes
            boxBrainDumpWebView.isHidden = false
            stackViewOldNotes.isHidden = true
            btnTryNewBrainDump.isHidden = true
            webView.isHidden = false
            btnToggleOldVersion.isHidden = !hasEverSwitchedToWebview

            if hasOldContent {
                applyWebViewTopConstraintBelowToggle()
            }

            loadWebView()
        } else {
            // Has old content and hasn't switched yet — show text editor + Try button
            boxBrainDumpWebView.isHidden = true
            stackViewOldNotes.isHidden = false
            textViewOldNotes.string = existingNotes
            btnTryNewBrainDump.isHidden = false
            btnToggleOldVersion.isHidden = true
            webView.isHidden = true
        }
    }
    
    func loadWebView() {
        // ?open=braindump lands the webview directly in the Brain Dump section (web_dashboard #3624).
        let urlString = "https://dashboard.focusbear.io/webview/notes?open=braindump"
        if let link = URL(string: urlString) {
            // Reset the one-shot guard so the initial brain-dump content is
            // injected once for this fresh load of the notes page.
            hasInjectedInitialBrainDump = false
            let request = URLRequest(url: link)
            self.webView.load(request)
        }
    }
    
    private func applyWebViewTopConstraintBelowToggle() {
        guard let parentView = webView.superview else { return }
        for constraint in parentView.constraints {
            if (constraint.firstItem as? WKWebView) == webView && constraint.firstAttribute == .top {
                parentView.removeConstraint(constraint)
            }
        }
        let newTopConstraint = NSLayoutConstraint(
            item: webView!,
            attribute: .top,
            relatedBy: .equal,
            toItem: btnToggleOldVersion,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 8
        )
        parentView.addConstraint(newTopConstraint)
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
    
    @IBAction func btnTryNewBrainDumpClicked(_ sender: Any) {
        let existingNotes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        if !existingNotes.isEmpty {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(existingNotes, forType: .string)
        }
        isShowingOldVersion = false
        hasEverSwitchedToWebview = true
        stackViewOldNotes.isHidden = true
        boxBrainDumpWebView.isHidden = false
        btnTryNewBrainDump.isHidden = true
        btnToggleOldVersion.isHidden = false
        webView.isHidden = false

        applyWebViewTopConstraintBelowToggle()

        allApiObject.capturePosthog(event: "brain-dump-switched-to-new-webview", metadata: [:])
        loadWebView()
    }

    @IBAction func btnToggleOldVersionClicked(_ sender: Any) {
        isShowingOldVersion = true
        hasEverSwitchedToWebview = false
        allApiObject.capturePosthog(event: "brain-dump-switched-to-old-version", metadata: [:])
        resetData()
    }

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

        // One-time migration (per user): push this user's local notes into the webview once, ever. Once
        // done, never re-push — that would clobber whatever the user has since typed in the webview.
        if UserDefaults.standard.value(forKey: kUserdefaultsBrainDumpSentToWebView) != nil { return }
        guard !isShowingOldVersion, !hasInjectedInitialBrainDump else { return }
        // Set the per-load guard up front so a second didFinish during this load doesn't start a second
        // poll loop; the persisted "sent" flag is only set once delivery is confirmed (see below).
        hasInjectedInitialBrainDump = true
        injectInitialBrainDumpNotes(into: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
}

extension brainDumpVc {
    /// One-time migration: push the desktop app's saved notes into the webview brain dump via the web
    /// bridge `window.updateBrainDumpFromDesktopApp(encodeURIComponent(notes))` — it `decodeURIComponent()`s
    /// its argument, so the notes MUST be URI-encoded. The bridge is registered only after React
    /// mount/hydration, so poll from the native side (each call returns whether the bridge was found +
    /// called) and persist the "sent" flag ONLY once a call actually lands — a failed/early load must not
    /// burn the one-time migration. (Tracked web-side in #2052: the editor doesn't yet render the
    /// dispatched notes, so until that ships the call won't confirm and will simply retry on the next load.)
    private func injectInitialBrainDumpNotes(into webView: WKWebView) {
        let existingNotes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        let escaped = existingNotes
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        // Returns true only when the bridge exists and was called; false means "not ready yet".
        let js = """
        (function() {
          if (typeof window.updateBrainDumpFromDesktopApp === 'function') {
            window.updateBrainDumpFromDesktopApp(encodeURIComponent('\(escaped)'));
            return true;
          }
          return false;
        })();
        """
        var attemptsLeft = 40   // ~4s total at 100ms spacing
        func attempt() {
            webView.evaluateJavaScript(js) { result, _ in
                if (result as? Bool) == true {
                    // Delivery confirmed — burn the one-time flag now (and only now).
                    UserDefaults.standard.set(true, forKey: kUserdefaultsBrainDumpSentToWebView)
                } else if attemptsLeft > 0 {
                    attemptsLeft -= 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: attempt)
                }
                // If the bridge never appears within the window, leave the flag unset so the next
                // fresh load retries the migration.
            }
        }
        attempt()
    }
}

