//
//  installHabitPacksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class installHabitPacksVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var btnSkip: hoverUnderlineButton!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var webView: WKWebView!
    
    var isWebViewBlank = false
    var suggestHabits:Bool = false
    let currentProgressLevel = 3
    var hasSkippedHabits = false
    var isEditHabitsLoaded = false
    
    var completionHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "save_suggested_activities")
        webView.configuration.userContentController.add(handler, name: "edit_suggested_activities")
        webView.configuration.userContentController.add(handler, name: "send_selected_habit_pack")
        webView.configuration.userContentController.add(handler, name: "send_installed_habit_pack_id")
        webView.configuration.userContentController.add(handler, name: "send_suggested_activities")
        webView.configuration.userContentController.add(handler, name: "routine_suggestions_step")
        
        webView.configuration.userContentController.add(handler, name: "setting_saved")
        webView.configuration.userContentController.add(AccessTokenRequestHandler.shared, name: AccessTokenRequestHandler.messageName)
        
        self.webView.navigationDelegate = self
        
        btnSkip.title = "Skip"
        
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkip.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
        }
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "install-habits-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: currentProgressLevel)
        showOnboardingBellIcon(view: self.view, screen: "habit-packs-screen")
    }

    
    func loadwebViewWithCompletion(suggestHabits:Bool, completionHandler: @escaping () -> Void){
        self.completionHandler = completionHandler
        if self.suggestHabits == suggestHabits{
            completionHandler()
            self.completionHandler = nil
            return;
        }
        loadWebView(suggestHabits: suggestHabits)
    }
    
    func loadWebView(suggestHabits:Bool){
        if self.suggestHabits == suggestHabits{
            return;
        }
        self.suggestHabits = suggestHabits
        isEditHabitsLoaded = false
        let addHabitsMode = suggestHabits ? "recommend" : "import"
        let url = "https://dashboard.focusbear.io/webview/routine-suggestion-revamp?bust_cache=\(getUuid())&add-habits-mode=\(addHabitsMode)"
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
                    
                    if self.isEditHabitsLoaded{
                        self.setSettingsToWebView()
                    }else{
                        self.setAccessTokenToWebView()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                            if self?.completionHandler != nil{
                                self?.completionHandler!()
                                self?.completionHandler = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if self.completionHandler != nil{
            completionHandler!()
            self.completionHandler = nil
        }
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if self.completionHandler != nil{
            completionHandler!()
            self.completionHandler = nil
        }
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
        loadWebView(suggestHabits: suggestHabits)
    }
    
    func reloadWebView(){
        loadEditHabitsView()
    }

    // Re-inject the freshly refreshed token via the same loader used on initial
    // load for the current mode (see webView(_:didFinish:)).
    func applyRefreshedAccessToken(requestId: String) {
        if isEditHabitsLoaded {
            setSettingsToWebView(requestId: requestId)
        } else {
            setAccessTokenToWebView(requestId: requestId)
        }
    }

    func setSettingsToWebView(requestId: String? = nil){
        let theme = getWindowTheme()
        var flags = "[\"settings-updated\",\"simple-mode\",\"save-settings-migrate-to-web\"]"
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var settingsJson = "{\"access_token\":\"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\",\"flags\":\(flags)}"
        if let requestId = requestId {
            settingsJson = String(settingsJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        
        let javascript = "loadSettingsData(\(settingsJson));"
        
        webView?.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print(html)
        })
        //load installed apps
        var arrInstalledApps = [String]()
        let urls = FileManager.default.urls(for: .applicationDirectory, in: [.systemDomainMask, .localDomainMask])
        let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey,URLResourceKey.nameKey]
       
        for url in urls{
            let array = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
            if array != nil{
                for appUrl in array!{
                    
                    if appUrl.pathExtension == "app"{
                        let appName = appUrl.deletingPathExtension().lastPathComponent
                        print(appName)
                        arrInstalledApps.append(appName)
                    }else{
                        if appUrl.isDirectory{
                            let arrAppInFolder = try? FileManager.default.contentsOfDirectory(at: appUrl, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
                            if arrAppInFolder != nil{
                                for appUrl in arrAppInFolder!{
                                    if appUrl.pathExtension == "app"{
                                        let appName = appUrl.deletingPathExtension().lastPathComponent
                                        print(appName)
                                        arrInstalledApps.append(appName)
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
        }
        
        
        addLog(text: "Load Installed Apps to web settings:- \(arrInstalledApps)")
        let mutableDic = NSMutableDictionary()
        mutableDic["installedApps"] = arrInstalledApps
        
        do {
            let data = try (JSONSerialization.data(withJSONObject: mutableDic, options: .prettyPrinted))
            if let str = String(data: data, encoding: String.Encoding.utf8){
                print(str)
                
             
                let script = "LoadInstalledApps(\(str));"
                
                webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                    print(error)
                    print(html)
                })
                
            }
        } catch let error as NSError {
            print(error)
        }

    }
    
    func loadEditHabitsView(){
        isEditHabitsLoaded = true
        var settingUrl = "https://dashboard.focusbear.io"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            if let url = settings.value(forKey: "settingUrlNew") as? String{
                settingUrl = url
            }
        }
       
        var url = "\(settingUrl)/webview/settings?bust_cache=\(getUuid())"//&device_id=\(currentDeviceId)"
        
        var fileURL = URL(string: url)
        if fileURL == nil{
            addLog(text: "url is nil")
            url = settingUrl
            fileURL = URL(string: url)
        }
        
        let request = NSMutableURLRequest(url: fileURL!)

        webView!.load(request as URLRequest)
    }
    
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    
    func setAccessTokenToWebView(requestId: String? = nil){
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
        
        let theme = getWindowTheme()
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var stringJson1 = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\",\"type\":\"mac\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\",\"long_term_goals\":\(goalsString)}"
        if let requestId = requestId {
            stringJson1 = String(stringJson1.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        
        let javascript = "loadMetaDataForRoutineSuggestion(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }

    @objc func showNextView(){
        addLog(text: "[user-action] installHabitPacksVc:- showNextView")
        hasSkippedHabits = false
        enableBreaksFromOnboarding()
        // Habits is the last setup section now (blocking already happened): go to the schedule step.
        getOnboardingVcObject().navigate(to: ._ASK_CREATE_BLOCKING_SCHEDULE_)
    }

    /// Turn breaks on by default coming out of onboarding, and seed a sensible 60-minute default frequency
    /// (unless the user/server already set one) so new users get an hourly break out of the box.
    private func enableBreaksFromOnboarding() {
        UserDefaults.standard.set(true, forKey: kUserdefaultsBreaksEnabledFromOnboarding)
        // Seed the 60-min default into the live global only. It's persisted to break_after_minutes with
        // the valid onboarding settings save in AppDelegate.initialWork (isFirstTime) — a standalone
        // full-settings PUT here 400s because the fresh user's times/activities aren't set yet.
        breakAfterMinutes = 60
    }
    
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] installHabitPacksVc:- btnSkipClicked")
        if isEditHabitsLoaded{
            // has saved habit once
            addLog(text: "has saved habit once")
            showNextView()
            return;
        }
        allApiObject.capturePosthog(event: "set-up-habits-webview-skipped", metadata: [:])
        hasSkippedHabits = true
        enableBreaksFromOnboarding()
        // Habits is the last setup section now (blocking already happened): go to the schedule step.
        getOnboardingVcObject().navigate(to: ._ASK_CREATE_BLOCKING_SCHEDULE_)
    }
}
