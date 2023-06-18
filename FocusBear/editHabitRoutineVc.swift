//
//  editHabitRoutineVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class editHabitRoutineVc: NSViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "setting_saved")
        webView.configuration.userContentController.add(handler, name: "open_marketplace")
        webView.configuration.userContentController.add(handler, name: "user_edited_settings")
        
        let stringTime = getStringFromDateInUtc(date: Date(), dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        var routine = ""
        if currentState == ._MORNING_HABIT_{
            routine = "morning"
        }else if currentState == ._EVENING_HABIT_{
            routine = "evening"
        }
        
        let url = "https://settings.focusbear.io?bust_cache=$\(stringTime)&edit_specific_routine=\(routine)"
        
        let  fileURL = URL(string: url)
        self.webView.navigationDelegate = self
        
        let request = NSMutableURLRequest(url: fileURL!)
        webView!.load(request as URLRequest)
        
    }
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "edit-habits", metadata: [:])
       
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.setSettingsToWebView()
            }
        }
    }
    
    func setSettingsToWebView(){
        let focusbearEnv = "focusbearEnv('mac');"
        
        webView?.evaluateJavaScript(focusbearEnv,completionHandler: { (html: Any?, error: Error?) in
            print(html)
        })
        
        //load settings
        
        var stringjson = ""
        if let text = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            stringjson = text
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    
                    let text2 = try String(contentsOf: url, encoding: .utf8)
                    stringjson = text2
                    
                } catch {
                    // handle error
                }
                
            }
        }

        
        let stringJson1 = "{\"settings\": \(stringjson),\"metadata\": {\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\"}}"
        
        let javascript = "loadSettingsData(\(stringJson1));"
        
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
    var alertSettingChanged:NSAlert?
    func jsonReceivedFromWebView(jsonResult: NSDictionary){
        allApiObject.isSettingsValid(settings: jsonResult, completionHandler: {dic,statusCode  in
            DispatchQueue.main.async {
                isGettingSchema = false
                
                
                if dic == nil{
                    let alert = NSAlert()
                    alert.setSharingType()
                    alert.alertStyle = .informational
                    
                    var schemaError = "Your settings cannot be validated."
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
                        self.alertSettingChanged = NSAlert()
                        self.alertSettingChanged!.setSharingType()
                        self.alertSettingChanged!.alertStyle = .informational
                        allApiObject.capturePosthog(event: "save-edited-habits", metadata: [:])
                        var settingIsValidText = "Your settings have been validated and will be applied now."
                        var buttonOkText = "OK"
                        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                            settingIsValidText = settings.value(forKey: "settingIsValidText") as? String ?? settingIsValidText
                            buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                        }
                        
                        self.alertSettingChanged!.messageText = settingIsValidText
//                        self.alertSettingChanged!.informativeText = "00:15"
                        self.alertSettingChanged!.addButton(withTitle: buttonOkText)
                        
                        self.startTimer(durationSeconds: 15)
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
                        UserDefaults.standard.set(true, forKey: kUserdefaultsEditHabitsOnce)
                        self.alertSettingChanged!.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                // self.setData()
                                appdelegate?.quitAndRestartApp()
                            }
                            
                            
                        })
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
}
