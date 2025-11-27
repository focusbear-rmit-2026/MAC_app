//
//  blockingScheduleVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/09/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class blockingScheduleVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {// not in use 

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    

    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var radioBtnFirst: NSButton!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var radioBtnSecond: NSButton!
    @IBOutlet weak var lblDescriptionThird: NSTextField!
    @IBOutlet weak var radioBtnThird: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Blocking Schedule"

        
        lblSubTitle.stringValue = "When do you want to block distracting sites?"
        radioBtnFirst.title = "Automatically (until the end of the workday)"
        lblDescriptionFirst.stringValue = "Block distracting sites until you finish your work/study. You'll get some free time before bed (check your socials guilt free!). When it's time to sleep, sites are blocked again."
        radioBtnSecond.title = "Manually (when I switch it on)"
        lblDescriptionSecond.stringValue = "Block distracting sites when you click the Start Focus Session button"
        radioBtnThird.title = "Advanced (customised blocking schedule)"
        lblDescriptionThird.stringValue = "Coming soon"
        
        
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "blockingScheduleSettingTitle") as? String ?? lblTitle.stringValue
        }
        
        
        if let onboardingBlockingScheduleVcInfo = configjson.value(forKey: "onboardingBlockingScheduleVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            radioBtnFirst.title = onboardingBlockingScheduleVcInfo.value(forKey: "radioBtnFirstText") as? String ?? radioBtnFirst.title
            lblDescriptionFirst.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            radioBtnSecond.title = onboardingBlockingScheduleVcInfo.value(forKey: "radioBtnSecondText") as? String ?? radioBtnSecond.title
            lblDescriptionSecond.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            radioBtnThird.title = onboardingBlockingScheduleVcInfo.value(forKey: "radioBtnThirdText") as? String ?? radioBtnThird.title
            lblDescriptionThird.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "descriptionThirdText") as? String ?? lblDescriptionThird.stringValue
        }
        
        self.webView.navigationDelegate = self
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "setting_saved")
        
        loadWebView()
        
        radioBtnThird.isEnabled = false
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.blockingSchedule == ._UNTIL_I_FINISH_WORK_{
            radioBtnFirst.state = .on
            radioBtnSecond.state = .off
            radioBtnThird.state = .off
        }else if SettingsManagerObject.blockingSchedule == ._WHEN_START_FOCUS_SESSION_{
            radioBtnFirst.state = .off
            radioBtnSecond.state = .on
            radioBtnThird.state = .off
        }else if SettingsManagerObject.blockingSchedule == ._CUSTOM_SCHEDULE_{
            radioBtnFirst.state = .off
            radioBtnSecond.state = .off
            radioBtnThird.state = .on
        }
    }
    
    @IBAction func radioBtnFirstClicked(_ sender: Any) {
        radioBtnSecond.state = .off
        radioBtnThird.state = .off
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.blockingSchedule = ._UNTIL_I_FINISH_WORK_
        allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"until_i_finish_work"])
    }
    
    @IBAction func radioBtnSecondClicked(_ sender: Any) {
        radioBtnFirst.state = .off
        radioBtnThird.state = .off
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.blockingSchedule = ._WHEN_START_FOCUS_SESSION_
        allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"when_i_tell_you_to"])
    }
    
    @IBAction func radioBtnThirdClicked(_ sender: Any) {
        radioBtnFirst.state = .off
        radioBtnSecond.state = .off
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.blockingSchedule = ._CUSTOM_SCHEDULE_
        allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"on_a_custom_schedule"])
    }
    
    func loadWebView(){
        var settingUrl = "https://dashboard.focusbear.io"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            if let url = settings.value(forKey: "settingUrlNew") as? String{
                settingUrl = url
            }
        }
        
        var url = "\(settingUrl)?bust_cache=\(getUuid())&edit_specific_routine=timing&device_id=\(currentDeviceId)"
        var  fileURL = URL(string: url)
        if fileURL == nil{
            addLog(text: "url is nil")
            url = "\(settingUrl)?edit_specific_routine=timing&device_id=\(currentDeviceId)"
            fileURL = URL(string: url)
        }
        let request = NSMutableURLRequest(url: fileURL!)
        webView!.load(request as URLRequest)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                self.setSettingsToWebView()
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
    
    func setSettingsToWebView(){
        let theme = getWindowTheme()
        
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var flags = "[\"settings-updated\"]"
        if SettingsManagerObject.isGeekModeEnabled{
            flags = "[\"settings-updated\",\"geek-mode\"]"
        }else{
            flags = "[\"settings-updated\",\"simple-mode\"]"
        }
        let settingsJson = "{\"access_token\":\"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"theme\":\"\(theme)\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\",\"flags\":\(flags)}"
        let javascript = "loadSettingsData(\(settingsJson));"
        
        webView?.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
        
        
        //load installed apps
        var arrInstalledApps = [String]()
        let urls = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
        let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey,URLResourceKey.nameKey]
        let array = try? FileManager.default.contentsOfDirectory(at: urls[0], includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
        if array != nil{
            for appUrl in array!{
                
                if appUrl.pathExtension == "app"{
                    let appName = appUrl.deletingPathExtension().lastPathComponent
                    print(appName)
                    arrInstalledApps.append(appName)
                }else{
                    if appUrl.lastPathComponent == "Utilities"{
                        let arrUtilitiesApp = try? FileManager.default.contentsOfDirectory(at: appUrl, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
                        if arrUtilitiesApp != nil{
                            for appUrl in arrUtilitiesApp!{
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
        let mutableDic = NSMutableDictionary()
        mutableDic["installedApps"] = arrInstalledApps
        
        do {
            let data = try (JSONSerialization.data(withJSONObject: mutableDic, options: .prettyPrinted))
            if let str = String(data: data, encoding: String.Encoding.utf8){
                print(str)
                
             
                let script = "LoadInstalledApps(\(str));"
                
                webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                    print(html)
                })
                
            }
        } catch let error as NSError {
            print(error)
        }
        
        
        // load focus names
        
        var arrFocusNames = [[String:String]]()
        for i in 0..<arrFocusType.count{
            if let name = arrFocusType[i]["name"] as? String{
                let dic = ["id":arrFocusType[i]["id"] as? String ?? "", "name":name]
                arrFocusNames.append(dic)
            }
        }
        
        
        let focusNamesDic = NSMutableDictionary()
        focusNamesDic["focusNames"] = arrFocusNames
        
        do {
            let data = try (JSONSerialization.data(withJSONObject: focusNamesDic, options: .prettyPrinted))
            if let str = String(data: data, encoding: String.Encoding.utf8){
                print(str)
                
             
                let script = "LoadFocusNames(\(str));"
                
                webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                    print(html)
                })
                
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func alertSettingsNotValid(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var schemaError = "Your settings could not be validated. The app needs to be restarted."
        var buttonOkText = "OK"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            schemaError = settings.value(forKey: "schemaError") as? String ?? schemaError
            buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
        }
        alert.messageText = schemaError
        alert.addButton(withTitle: buttonOkText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
            }
            
            appdelegate?.quitAndRestartApp()
        })
    }
    
    func alertSettingsSaved(){
        self.alertSettingChanged = NSAlert()
        self.alertSettingChanged!.setSharingType()
        self.alertSettingChanged!.alertStyle = .informational
        allApiObject.capturePosthog(event: "save-edited-habits", metadata: [:])
        var settingIsValidText = "Saved! Restarting the app so your new habit timing works."
        var buttonOkText = "Restart now"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            settingIsValidText = settings.value(forKey: "settingIsValidText") as? String ?? settingIsValidText
            buttonOkText = settings.value(forKey: "buttonRestartNow") as? String ?? buttonOkText
        }
        
        self.alertSettingChanged!.messageText = settingIsValidText
        self.alertSettingChanged!.addButton(withTitle: buttonOkText)
        self.startTimer(durationSeconds: 15)
        self.alertSettingChanged!.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                appdelegate?.quitAndRestartApp()
            }
        })
    }
    var alertSettingChanged:NSAlert?
    func jsonReceivedFromWebView(jsonResult: NSDictionary){
        addLog(text: "blocking Schedule:- func jsonReceivedFromWebView")
        addLog(text: "settings json is:- \(jsonResult)")
        allApiObject.isSettingsValid(settings: jsonResult, isOnboarding:false, completionHandler: {dic,statusCode  in
            DispatchQueue.main.async {
                isGettingSchema = false
                
                
                if dic == nil{
                    let alert = NSAlert()
                    alert.setSharingType()
                    alert.alertStyle = .informational
                    
                    var schemaError = "Your settings could not be validated. The app needs to be restarted."
                    var buttonOkText = "OK"
                    if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                        schemaError = settings.value(forKey: "schemaError") as? String ?? schemaError
                        buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                    }
                    alert.messageText = schemaError
                    alert.addButton(withTitle: buttonOkText)
                    
                    alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                        if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        }
                        
                        appdelegate?.quitAndRestartApp()
                    })
                }else{
                    
                    if statusCode == 200{
                        self.alertSettingsSaved()
                        do {
                            let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                            
                            print(jsonResultData)
                            
                            if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                print()
                                UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                            }
                        } catch let myJSONError {
                            print(myJSONError)
                        }
                    }else{
                        
                        
                        let alert = NSAlert()
                        alert.setSharingType()
                        alert.alertStyle = .informational
                        
                        var settingIsNotValidText = "Sorry it seems like your settings aren’t valid. Please generate settings at focusbear.io/settings"
                        var buttonOkText = "OK"
                        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                            settingIsNotValidText = settings.value(forKey: "settingIsNotValidText") as? String ?? settingIsNotValidText
                            buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                        }
                        
                        alert.messageText = settingIsNotValidText
                        if let message = dic?.value(forKey: "message") as? NSArray{
                            alert.informativeText = "\(message)"
                        }
                        
                        alert.addButton(withTitle: buttonOkText)
                        
                        //let buttons = alertremoveitem.buttons
                        // alertremoveitem.beginSheetModal(for: self.window!, completionHandler: nil)
                        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                
                            }
                            appdelegate?.quitAndRestartApp()
                        })
                    }
                    
                    
                }
            }
        })
    }
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    func startTimer(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }

        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.alertSettingChanged?.informativeText = "\(minute):\(second)"
        }else{
            self.alertSettingChanged?.informativeText = "\(hour):\(minute):\(second)"
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    func setProgres(){
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"

        if hour.count == 1 {
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {

            if h == 0{
                self.alertSettingChanged?.informativeText = "\(minute):\(second)"
            }else{
                self.alertSettingChanged?.informativeText = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.alertSettingChanged?.window.close()
                appdelegate?.quitAndRestartApp()
            }
        }
    }

    @objc func performTimerCount() {
        currentTimer += 1
        setProgres()
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            tabStrictnessContainerVcObj?.showStrictnessView()
        }
    }
}
