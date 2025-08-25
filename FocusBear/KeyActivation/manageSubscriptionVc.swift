//
//  manageSubscriptionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class manageSubscriptionVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var webView: WKWebView!
    let handler = MessageHandler()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        webView.configuration.userContentController.add(handler, name: "send_user_subscription_status")
        loadWebView()
    }
    
    func loadWebView(){
        let url = "https://dashboard.focusbear.io/webview/manage-subscription?bust_cache=\(getUuid())"
        let  fileURL = URL(string: url)
        let request = NSMutableURLRequest(url: fileURL!)
        webView.load(request as URLRequest)
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
    
    override func viewDidAppear() {
        setAccessTokenToWebView()
    }

    func setAccessTokenToWebView(){
        let theme = getWindowTheme()
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson1 = "{\"access_token\":\"\(appdelegate!.credential?.accessToken ?? "")\",\"type\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\"}"
        
        let javascript = "loadMetaDataForSubscription(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }

    @IBAction func btnCloseClicked(_ sender: Any) {
        self.dismiss(self)
        if upgradeNowVcObj != nil{
            if upgradeNowVcObj?.isViewVisible ?? false{
                upgradeNowVcObj?.syncPaymentStatus()
            }
        }
        
        if trialExpiredNagWcObj != nil{
            if trialExpiredNagWcObj?.window?.isVisible ?? false{
                trialExpiredNagObj?.syncPaymentStatus()
            }
        }
        
        if upgradeToProNagWcObj != nil{
            if upgradeToProNagWcObj?.window?.isVisible ?? false{
                upgradeToProNagVcObj?.syncPaymentStatus()
            }
        }
        
    }
}
