//
//  onboardingFocusExplainVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/07/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class onboardingFocusExplainVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var url = "https://www.youtube.com/watch?v=ssiLisLbN2o"
    var videoStarted = false
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "Get into deep focus"
        lblSubTitle.stringValue = "Focus Bear can help you get more deep work done by blocking distractions. You tell the app what you want to do and it uses AI to keep you on track."
        btnContinue.title = "Got it"

        if let onboardingFocusExplainVcInfo = configjson.value(forKey: "onboardingFocusExplainVcInfo") as? NSDictionary{
            lblTitle.stringValue = onboardingFocusExplainVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = onboardingFocusExplainVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnContinue.title = onboardingFocusExplainVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            url = onboardingFocusExplainVcInfo.value(forKey: "video_url") as? String ?? url
        }
        
        self.webView.navigationDelegate = self
        loadWebView()
        getOnboardingHabitExplainVcObject().loadView()
        
        
        
        // Inject JavaScript to observe play event
        let js = """
                document.addEventListener('play', function(event) {
                    if (event.target.tagName === 'VIDEO') {
                        window.webkit.messageHandlers.focusExplainVideoPlayHandler.postMessage("play");
                    }
                }, true);
                """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        self.webView.configuration.userContentController.addUserScript(userScript)
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "focusExplainVideoPlayHandler")
    }
    
    func videoStartedByUser(){
        if videoStarted{
            return;
        }
        videoStarted = true
        allApiObject.capturePosthog(event: "focus-explain-screen-video-played", metadata: [:])
    }
    func loadWebView(){
        var videoUrl = url
        if videoUrl.lowercased().contains("watch?v="){
            if videoUrl.contains("&"){// removing additional param
                if let firstItem =  videoUrl.components(separatedBy: "&").first{
                    videoUrl = firstItem
                }
            }
            videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
        }else{
            // doing this beacuse if video is embedded than it will not play
            if videoUrl.lowercased().contains("https://youtu.be/"){
                if let lastItem =  videoUrl.components(separatedBy: "/").last{
                    videoUrl = "https://www.youtube.com/embed/" + lastItem
                }
                
            }
        }
        let link = URL(string:videoUrl)!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "focus-explain-screen")
    }
    
    override func viewWillDisappear() {
        
    }

    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
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
    
    func reloadClicked(webView:WKWebView){
        loadWebView()
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
        hideOnboardingBellIcon(view: self.view)
        
        addLog(text: "[user-action] Onboarding Focus Explain view:- button Gotit clicked.")
        self.view.window?.contentViewController = getOnboardingHabitExplainVcObject()
        addLog(text: "Showing Onboarding Habit Explain view.")
        allApiObject.capturePosthog(event: "routine-explain-screen-shown", metadata: [:])
    }
}
