//
//  addTaskVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/10/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class todoListToolVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var webView: WKWebView!
    let handler = MessageHandler()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.webView.navigationDelegate = self
    }
    override func viewWillDisappear() {
//        update all tags because it may be posssible that user has created some tags in webview
        allApiObject.getFocusModeTags(completionHandler: {arrJson in
            
        })
    }
    func reloadData(){
        let webUrl:String = "https://dashboard.focusbear.io/webview/tools-todo-list?bust_cache=\(getUuid())"
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
        reloadData()
    }
    
    func setAccessTokenToWebView(){
        let intention = whatToAchieveInFocusBlock
        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\"}"
        
        if !intention.isEmpty{
            stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"intention\":\"\(intention)\"}"
        }
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadAccessTokenForToDo) { loadAccessTokenForToDo(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }
    
}
