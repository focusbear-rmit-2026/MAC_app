//
//  selectJsonVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/01/22.
//  .
//

import Cocoa
//import JSONSchema
import WebKit
class selectJsonVc: NSViewController, NSTextViewDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var boxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var boxWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var customBox: NSBox!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var lblVisitUrl: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnSave: cursorButton!
    @IBOutlet var textViewJson: NSTextView!
    @IBOutlet weak var textscrollView: NSScrollView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnAdvanced: NSButton!
    @IBOutlet weak var btnEditSettings: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        customBox.isHidden = false
        btnCancel.isHidden = true
        selectJsonVcObj = self
        textViewJson.delegate = self
        textViewJson.font = NSFont(name: btnSave!.font?.familyName ?? "", size: 14)
        lblTitle.stringValue = "Enter settings JSON below:"
        lblVisitUrl.stringValue = "Visit focusbear.io/settings-generator to generate settings"
        
        btnSave.title = "Save"
        btnEditSettings.title = "Edit Settings"
        btnAdvanced.title = "Advanced"
        lblDescription.stringValue = "Click on \"Edit Settings\" to modify your existing settings.\nIf you are an advanced user click on \"Advanced\" to view or edit settings JSON"
        
        
        
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            if let title = settings.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let buttonSaveText = settings.value(forKey: "buttonSaveText") as? String{
                btnSave.title = buttonSaveText
            }
            
            if let buttonEditSettingsText = settings.value(forKey: "buttonEditSettingsText") as? String{
                btnEditSettings.title = buttonEditSettingsText
            }
            if let buttonAdvancedText = settings.value(forKey: "buttonAdvancedText") as? String{
                btnAdvanced.title = buttonAdvancedText
            }
            if let description = settings.value(forKey: "description") as? String{
               lblDescription.stringValue = description
            }
            if let visitText = settings.value(forKey: "visitText") as? String, let settingUrl = settings.value(forKey: "settingUrl") as? String{
                if visitText.localizedCaseInsensitiveContains("<SETTINGURL>"){
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.alignment = .center
                    let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
                    let arr = visitText.components(separatedBy: "<SETTINGURL>")
                    let mainstr =  NSMutableAttributedString()
                    for i in 0..<arr.count{
                        let string = arr[i]
                        if !string.isEmpty{
                            let str = NSMutableAttributedString(string: string, attributes: attrs)
                            if i != arr.count - 1{
                                let paragraph = NSMutableParagraphStyle()
                                paragraph.alignment = .center
                                let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
                                let attrString: NSAttributedString = NSAttributedString(string: settingUrl, attributes: attrs)
                                str.append(attrString)
                            }
                            mainstr.append(str)
                        }
                    }
                    lblVisitUrl.attributedStringValue = mainstr
                }
            }
            
        }
        
        let handler = MessageHandler()
        webview.configuration.userContentController.add(handler, name: "setting_saved")
        webview.configuration.userContentController.add(handler, name: "open_marketplace")
        webview.configuration.userContentController.add(handler, name: "user_edited_settings")
        
        let stringTime = getStringFromDateInUtc(date: Date(), dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        let url = "https://settings.focusbear.io?bust_cache=$\(stringTime)"

        let  fileURL = URL(string: url)
        self.webview.navigationDelegate = self
//        webview!.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
        let request = NSMutableURLRequest(url: fileURL!)
        webview!.load(request as URLRequest)
        
        
        //1200/950
//        boxWidthConstraint.constant = 500
//        boxHeightConstraint.constant = 350
        
        textscrollView.isHidden = true
        lblTitle.isHidden = true
        lblVisitUrl.isHidden = true
//        btnCancel.isHidden = true
        btnSave.isHidden = true
        customBox.isHidden = false
        boxWidthConstraint.constant = 1000
        boxHeightConstraint.constant = 600
        lblDescription.isHidden = true

        webview.backgroundcolor = NSColor.clear
    }
    @IBAction func btnOldViewClicked(_ sender: Any) {
        customBox.isHidden = true
        textscrollView.isHidden = false
        lblTitle.isHidden = false
        btnSave.isHidden = false
        boxWidthConstraint.constant = 1000
        boxHeightConstraint.constant = 600
        lblDescription.isHidden = true
    }
    @IBAction func btnNewTabViewCicked(_ sender: Any) {
        customBox.isHidden = false
        textscrollView.isHidden = true
        lblTitle.isHidden = true
        lblVisitUrl.isHidden = true
//        btnCancel.isHidden = true
        btnSave.isHidden = true
        boxWidthConstraint.constant = 1000
        boxHeightConstraint.constant = 600
        lblDescription.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.setSettingsToWebView()
            }
        }
    }
    override func viewDidAppear() {
        
    }
    func setSettingsToWebView(){
        let focusbearEnv = "focusbearEnv('mac');"
        
        webview?.evaluateJavaScript(focusbearEnv,completionHandler: { (html: Any?, error: Error?) in
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
                    //                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    //
                    //                    do {
                    //                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    //                            jsonResult = dicResult
                    //                            print(jsonResult)
                    //
                    //                        }
                    //
                    //                    }catch {
                    //                        print(error)
                    //                    }
                    
                } catch {
                    // handle error
                }
                
            }
        }

        
        let stringJson1 = "{\"settings\": \(stringjson),\"metadata\": {\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\"}}"
        
        let javascript = "loadSettingsData(\(stringJson1));"
        
        webview?.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
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
                
                webview?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
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
                
                webview?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                    print(html)
                })
                
            }
        } catch let error as NSError {
            print(error)
        }
       
        
    }
    override func viewWillAppear() {
        preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: 1000, height: 600))
        allApiObject.capturePosthog(event: "edit-habits", metadata: [:])
        setData()
    }
    
    func setData(){
        //        var jsonResult = NSDictionary()
        
        btnSave.isEnabled = false
        if let text = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            textViewJson.string = text
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    
                    let text2 = try String(contentsOf: url, encoding: .utf8)
                    textViewJson.string = text2
                    //                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    //
                    //                    do {
                    //                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    //                            jsonResult = dicResult
                    //                            print(jsonResult)
                    //
                    //                        }
                    //
                    //                    }catch {
                    //                        print(error)
                    //                    }
                    
                } catch {
                    // handle error
                }
                
            }
        }
        //        textViewJson.string = jsonResult.description
    }
    //    func jsonToString(json: AnyObject){
    //        do {
    //            let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
    //            let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
    //            print(convertedString) // <-- here is ur string
    //
    //        } catch let myJSONError {
    //            print(myJSONError)
    //        }
    //
    //    }
    //    @IBAction func btnLinkClicked(_ sender: Any) {
    //        if let url = URL(string: "http://focusbear.io/settings-generator") {
    //            NSWorkspace.shared.open(url)
    //        }
    //    }focusbear.io/settings-generator
    
   
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
    @IBAction func btnSaveClicked(_ sender: Any) {

        isGettingSchema = true
        btnSave.isEnabled = false
//        btnCancel.isEnabled = false
        loader.startAnimation(self)
        var text = self.textViewJson.string.replacingOccurrences(of: "”", with: "\"")
        text = text.replacingOccurrences(of: "“", with: "\"")
        self.textViewJson.string = text
        if let data = self.textViewJson.string.data(using: String.Encoding.utf8) {
            
            do {
                let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                
                allApiObject.isSettingsValid(settings: jsonResult, completionHandler: {dic,statusCode  in
                    DispatchQueue.main.async {
                        isGettingSchema = false
                        self.btnSave.isEnabled = true
        //                self.btnCancel.isEnabled = true
                        self.loader.stopAnimation(self)
                        
                        if dic == nil && statusCode == 0{
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
                                
                                
                            })
                        }else{
                            
                            if statusCode == 200{

                                
                                do {
                                    let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                    
                                    print(jsonResultData)
                                    
                                    if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                        UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                        appdelegate?.quitAndRestartApp()
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
                                        self.setData()
                                    }
                                    
                                    
                                })
                                
                            }
                            
                        }
                    }
                })
                
            } catch let error as NSError {
                isGettingSchema = false
                self.btnSave.isEnabled = true
                self.loader.stopAnimation(self)
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
                alert.informativeText = error.localizedDescription
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    }
                    
                    self.setData()
                })
                print(error)
            }
            
        }
        
        
        
//        
//        Vishnu Sharma
//        WTLVishnu45
        
        //  } catch let error as NSError {
        //     print(error)
        // }
        //   }
        
        
    }
    var alertSettingChanged:NSAlert?

    func jsonReceivedFromWebView(jsonResult: NSDictionary){
        
        
        isGettingSchema = true
        
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
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }
        if textView == textViewJson {
            if textViewJson.string.isEmpty {
                btnSave.isEnabled = false
            }else {
                btnSave.isEnabled = true
            }
        }
    }
}//user-edited-settings
class MessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        print(message.body)
        print("call back hua")
        if message.name == "open_marketplace"{
            print(message.body)
            if let url = URL(string: message.body as? String ?? ""){
                NSWorkspace.shared.open(url)
            }
        }else if message.name == "open_android_app"{
            print(message.body)
            if let url = URL(string: message.body as? String ?? ""){
                NSWorkspace.shared.open(url)
            }
        }else if message.name == "open_ios_app"{
            print(message.body)
            if let url = URL(string: message.body as? String ?? ""){
                NSWorkspace.shared.open(url)
            }
        }else if message.name == "setting_saved"{
            if let data = (message.body as? String ?? "").data(using: String.Encoding.utf8) {
                
                do {
                    let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                    print(jsonResult)
                    
                    
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                        if (mainWindowControllerObj?.window?.isVisible ?? false) && editHabitRoutineVcObj != nil{
                            editHabitRoutineVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
                        }else{
                            selectJsonVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
                        }
                    }else{
                        selectJsonVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
                    }
                }
                catch{
                    
                }
            }

        }else if message.name == "user_edited_settings"{
            
//            if let data = (message.body as? String ?? "").data(using: String.Encoding.utf8) {
//
//                do {
//                    let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
//                    print(jsonResult)
//
////                    selectJsonVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
//
//                    isSettingsChanged = true
//                }
//                catch{
//
//                }
//            }
            
            
        }
        
        
        
        
        //        if message.body as? String ?? "" == "setting_saved"{
        //            print("correct")
        //        }
        
    }
}

//func makeWebView() -> WKWebView {
////    let preferences = WKPreferences()
////    preferences.javaScriptEnabled = true
//    let handler = MessageHandler()
//    let configuration = WKWebViewConfiguration()
//    configuration.userContentController.add(handler, name: "setting_saved")
//    configuration.preferences.javaScriptEnabled = true// = preferences
//    return WKWebView(frame: .zero, configuration: configuration)
//}



