//
//  surveyVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/09/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class surveyVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.webView.navigationDelegate = self
        loadWebView()
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "close_survey_ui")
    }
    
    func loadWebView(){
        let webUrl:String = "https://dashboard.focusbear.io/webview/survey?bust_cache=\(getUuid())"
        let link = URL(string:webUrl)!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                self.setAccessTokenToWebView()
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
                return;
            }
        }
        webViewLoadFailedVcObj = getWebViewLoadFailedVcObject()
        webViewLoadFailedVcObj!.customDelegate = self
        webViewLoadFailedVcObj?.webView = webView
        webView.addSubview(webViewLoadFailedVcObj!.view)
        webView.addConstraints(subView: webViewLoadFailedVcObj!.view)
    }
    
    func reloadClicked(webView:WKWebView){
        loadWebView()
    }
    
    func setAccessTokenToWebView(){
        var theme = "LIGHT"
        if preferencesWindowControllerObj != nil{
            if preferencesWindowControllerObj!.window!.hasDarkAppearance{
                theme = "DARK"
            }else {
                theme = "LIGHT"
            }
        }
        let stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"theme\":\"\(theme)\",\"lang\":\"\(currentLanguageCode)\"}"
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadAccessTokenForSurvey) { loadAccessTokenForSurvey(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }
}
