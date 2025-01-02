//
//  addTaskVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/09/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class addTaskVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    let handler = MessageHandler()
    var isAddingTask = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.webView.navigationDelegate = self
        
        webView.configuration.userContentController.add(handler, name: "submit_completed_tasks")
        webView.configuration.userContentController.add(handler, name: "get_selected_tasks")
        webView.configuration.userContentController.add(handler, name: "close_todo_task_ui")
        webView.configuration.userContentController.add(handler, name: "close_todo_focus_end_ui")
    }
    override func viewWillDisappear() {
        isWebViewUrlLodded = false
        
        //        update all tags because it may be posssible that user has created some tags in webview
        allApiObject.getFocusModeTags(completionHandler: {arrJson in
            
        })
    }
    var isWebViewUrlLodded = false
    func reloadData(isAddingTask:Bool){
        self.isAddingTask = isAddingTask
        loadRequest()
    }
    func loadRequest(){
        if !isWebViewUrlLodded{
            let stringTime = getStringFromDateInUtc(date: Date(), dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            var webUrl:String = ""
            if self.isAddingTask{
                webUrl = "https://dashboard.focusbear.io/webview/todo-list?bust_cache=$\(stringTime)"
            }else{
                webUrl = "https://dashboard.focusbear.io/webview/focus-end?bust_cache=$\(stringTime)"
            }
            let link = URL(string:webUrl)!
            let request = URLRequest(url: link)
            isWebViewUrlLodded = true
            self.webView.load(request)
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                if self.isAddingTask{
                    self.setAccessTokenToWebView()
                }else{
                    self.setAccessTokenAndTaksToWebView()
                }
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
        isWebViewUrlLodded = false
        loadRequest()
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
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\"}"
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadAccessTokenForToDo) { loadAccessTokenForToDo(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }
    
    
    func setAccessTokenAndTaksToWebView(){
        var theme = "LIGHT"
        if preferencesWindowControllerObj != nil{
            if preferencesWindowControllerObj!.window!.hasDarkAppearance{
                theme = "DARK"
            }else {
                theme = "LIGHT"
            }
        }
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        
        let totalDuration = focusModeActualDurationPerformed / 60
        
        let stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"tasks\":\(focusModeTaskString),\"total_duration\":\(totalDuration),\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\"}"
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadTasks) { loadTasks(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        if !isAddingTask{
            allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-closed", metadata: [:])
        }
        self.dismiss(self)
    }
}

