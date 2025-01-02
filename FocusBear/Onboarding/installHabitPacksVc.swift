//
//  installHabitPacksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/06/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class installHabitPacksVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var webView: WKWebView!
    var isWebViewBlank = false
    var morningRoutineDuration: Int = 0
    var eveningRoutineDuration: Int = 0
    let currentProgressLevel = 3
//    var isViewVisible = false
    override func viewDidLoad() {
        super.viewDidLoad()
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "save_suggested_activities")
        webView.configuration.userContentController.add(handler, name: "edit_suggested_activities")
        webView.configuration.userContentController.add(handler, name: "send_selected_habit_pack")
        webView.configuration.userContentController.add(handler, name: "send_installed_habit_pack_id")
        webView.configuration.userContentController.add(handler, name: "send_suggested_activities")
        webView.configuration.userContentController.add(handler, name: "routine_suggestions_step")
        self.webView.navigationDelegate = self
        
        loadWebView()
    }
    
    func loadWebView(){
        let url = "https://dashboard.focusbear.io/webview/routine-suggestion?bust_cache=\(getUuid())"
        let  fileURL = URL(string: url)
        let request = NSMutableURLRequest(url: fileURL!)
        webView.load(request as URLRequest)
        isWebViewBlank = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                if !self.isWebViewBlank{
                    self.removeWebViewLoadFailedView(webView: webView)
                    self.setAccessTokenToWebView()
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
        loadWebView()
    }
    
    override func viewWillAppear() {
//        isViewVisible = true
//        self.setAccessTokenToWebView()
    }
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: currentProgressLevel)
        showOnboardingBellIcon(view: self.view, screen: "habit-packs-screen")
    }

    override func viewWillDisappear() {
//        isViewVisible = false
        isWebViewBlank = true
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    
    func setAccessTokenToWebView(){
        let goals = UserDefaults.standard.object(forKey: kUserDefaultsCustomGoals) as? String ?? ""
        let arrGoals = [goals]
        var goalsString = "\(arrGoals)"//
        goalsString = goalsString.replacingOccurrences(of: "[", with: "{")
        goalsString = goalsString.replacingOccurrences(of: "]", with: "}")
        do {
            let data = try (JSONSerialization.data(withJSONObject: arrGoals, options: .prettyPrinted))
            if let str = String(data: data, encoding: String.Encoding.utf8){
                goalsString = str
            }
        } catch let error as NSError {
            print(error)
        }
        
        var theme = "LIGHT"
        if mainWindowControllerObj!.window!.hasDarkAppearance{
            theme = "DARK"
        }else {
            theme = "LIGHT"
        }
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson1 = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\",\"type\":\"mac\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\",\"long_term_goals\":\(goalsString)}"
        
        let javascript = "loadMetaDataForRoutineSuggestion(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
    
    var isShowingNextView = false
    
    @objc func showNextView(){
        if isShowingNextView{
            return;
        }
        isShowingNextView = true
        allApiObject.getSettings(isFirstTime: false, packId:"", completionHandler: {val in
            let settings = val?.mutableCopy() as? NSMutableDictionary
            self.morningRoutineDuration = 0
            self.eveningRoutineDuration = 0
            if settings != nil{
                
                if let morningHabits = settings!.value(forKey: "morning_activities") as? [NSDictionary] {
                    print("morningHabits")
                    print(morningHabits)
                    for habitDic in morningHabits {
                        let durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                        self.morningRoutineDuration += durationSeconds
                    }
                }
                if let eveningHabits = settings!.value(forKey: "evening_activities") as? [NSDictionary] {
                    print("eveningHabits")
                    print(eveningHabits)
                    for habitDic in eveningHabits {
                        let durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                        self.eveningRoutineDuration += durationSeconds
                        
                    }
                }
            }
            DispatchQueue.main.async {
                self.isShowingNextView = false
                mainViewControllerObj!.showAskWorkTimeVc()
            }
        })
    }
}
