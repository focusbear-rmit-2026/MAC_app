//
//  setUpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class setUpVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imgViewCustomiseFocusMode: NSImageView!
    @IBOutlet weak var imgViewCustomiseHabit: NSImageView!
    @IBOutlet weak var imgViewSetBlockedUrls: NSImageView!
    @IBOutlet weak var imgViewCompleteMorningRoutine: NSImageView!
    @IBOutlet weak var imgViewCompleteEveningRoutine: NSImageView!
    @IBOutlet weak var imgViewFocusSession: NSImageView!
    
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblTotalProgress: NSTextField!
    @IBOutlet weak var boxProgressFull: NSBox!
    @IBOutlet weak var boxProgressWidth: NSLayoutConstraint!
    @IBOutlet weak var boxProgress: NSBox!
   
    @IBOutlet weak var lblCustomiseFocusMode: NSTextField!
    @IBOutlet weak var lblCustomiseHabit: NSTextField!
    @IBOutlet weak var lblSetBlockedUrls: NSTextField!
    @IBOutlet weak var lblCompleteMorningRoutine: NSTextField!
    @IBOutlet weak var lblCompleteEveningRoutine: NSTextField!
    @IBOutlet weak var lblFocusSession: NSTextField!
    
    @IBOutlet weak var lblCustomiseFocusModeProgress: NSTextField!
    @IBOutlet weak var lblCustomiseHabitProgress: NSTextField!
    @IBOutlet weak var lblSetBlockedUrlsProgress: NSTextField!
    @IBOutlet weak var lblCompleteMorningRoutineProgress: NSTextField!
    @IBOutlet weak var lblCompleteEveningRoutineProgress: NSTextField!
    @IBOutlet weak var lblFocusSessionProgress: NSTextField!
    
    
    let copySystemPreferencesIndex = 0
    let alwaysDarkModeIndex = 1
    let neverDarkModeIndex = 2
    
    let viewWidthDefault = 1040
    let viewHeightDefault = 682
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLog(text: "statsVc viewdidload start")
        self.webView.navigationDelegate = self
        loadWebView()
        
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "open_android_app")
        webView.configuration.userContentController.add(handler, name: "open_ios_app")
        webView.configuration.userContentController.add(handler, name: "download_focus_summaries")
        addLog(text: "statsVc viewdidload end")
    }
    
    func loadWebView(){
        let url = "https://dashboard.focusbear.io/webview/stats?bust_cache=\(getUuid())"
        let  fileURL = URL(string: url)
        let request = NSMutableURLRequest(url: fileURL!)
        webView.load(request as URLRequest)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
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
    
    override func viewWillAppear() {
//        preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: viewWidthDefault, height: viewHeightDefault)) // todo need to check
    }
    override func viewDidAppear() {
        setAccessTokenToWebView()
    }

    func setAccessTokenToWebView(){
        var theme = "LIGHT"
        if mainWindowControllerObj != nil{
            if mainWindowControllerObj!.window!.hasDarkAppearance{
                theme = "DARK"
            }else {
                theme = "LIGHT"
            }
        }
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson1 = "{\"access_token\":\"\(appdelegate!.credential?.accessToken ?? "")\",\"type\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\"}"
        
        let javascript = "loadAccessTokenForStats(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
 
    override func viewWillDisappear() {

    }
}
