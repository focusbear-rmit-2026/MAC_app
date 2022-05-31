//
//  selectJsonVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 05/01/22.
//  .
//

import Cocoa
import JSONSchema
import WebKit
class selectJsonVc: NSViewController, NSTextViewDelegate {
    
    @IBOutlet weak var boxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var boxWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var customView: NSView!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var lblVisitUrl: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnSave: cursorButton!
    @IBOutlet var textViewJson: NSTextView!
    @IBOutlet weak var textscrollView: NSScrollView!
    //    @IBOutlet weak var webview: WKWebView!
    
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnAdvanced: NSButton!
    @IBOutlet weak var btnEditSettings: NSButton!
    //    var webview: WKWebView?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        customView.isHidden = true
        btnCancel.isHidden = true
        selectJsonVcObj = self
        textViewJson.delegate = self
        textViewJson.font = NSFont(name: btnSave!.font?.familyName ?? "", size: 14)
        lblTitle.stringValue = "Enter settings JSON below:"
        lblVisitUrl.stringValue = "Visit earnyourscreentime.com/settings-generator to generate settings"
//        btnCancel.stringValue = buttonCancelText
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
        
//        webview = makeWebView()
//        customView.addSubview(webview!)
//        customView.addConstraints(subView: webview!)
        let handler = MessageHandler()
        webview.configuration.userContentController.add(handler, name: "setting_saved")
        let url = "https://earn-your-screentime-settings.herokuapp.com/"//
        // let url = "file:///Users/prashant/Desktop/test.html"
        //"https://earn-your-screentime-settings.herokuapp.com/"//"https://earn-your-screentime-settings.herokuapp.com/"//http://jaininfotech.com/temp/test.html"//http://localhost:3000" //https://earn-your-screen-time-settings.herokuapp.com/"//"file:///Users/prashant/Desktop/test.html"
        let  fileURL = URL(string: url)

//        webview!.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
        let request = NSMutableURLRequest(url: fileURL!)
        webview!.load(request as URLRequest)
        
        
        //1200/950
        boxWidthConstraint.constant = 500
        boxHeightConstraint.constant = 350
        customView.isHidden = true
        textscrollView.isHidden = true
        lblTitle.isHidden = true
        lblVisitUrl.isHidden = true
//        btnCancel.isHidden = true
        btnSave.isHidden = true
        lblDescription.isHidden = false
        
        
        
        
    }
    @IBAction func btnOldViewClicked(_ sender: Any) {
        customView.isHidden = true
        textscrollView.isHidden = false
        lblTitle.isHidden = false
        lblVisitUrl.isHidden = false
//        btnCancel.isHidden = false
        btnSave.isHidden = false
        boxWidthConstraint.constant = 1000
        boxHeightConstraint.constant = 600
        lblDescription.isHidden = true
    }
    @IBAction func btnNewTabViewCicked(_ sender: Any) {
        customView.isHidden = false
        textscrollView.isHidden = true
        lblTitle.isHidden = true
        lblVisitUrl.isHidden = true
//        btnCancel.isHidden = true
        btnSave.isHidden = true
        boxWidthConstraint.constant = 1000
        boxHeightConstraint.constant = 600
        lblDescription.isHidden = true
    }
    override func viewDidAppear() {
        
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
        
        let javascript = "loadSettingsDataFromMac(\(stringjson));"
        
        webview?.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(html)
        })
        
        
        var arrInstalledApps = [String]()
        let urls = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
        let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey,URLResourceKey.nameKey]
        let array = try? FileManager.default.contentsOfDirectory(at: urls[0], includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
        if array != nil{
            for appUrl in array!{
                
                if appUrl.pathExtension == "app"{
                    let appName = appUrl.lastPathComponent
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
        //var jsonResult = NSDictionary()
        //        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
        //            //            jsonResult = dic
        //            if let data = stringDic.data(using: String.Encoding.utf8) {
        //
        //                do {
        //                    jsonResult = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
        //
        //                } catch let error as NSError {
        //                    print(error)
        //                }
        //            }
        //
        //        }
        //        if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
        //            let url = URL(fileURLWithPath: path)
        //            do {
        //                let data = try Data(contentsOf: url, options: .mappedIfSafe)
        //
        //                do {
        //                    if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
        //                        jsonResult = dicResult
        //                    }
        //
        //                }catch {
        //                    print(error)
        //                }
        //            } catch {
        //                // handle error
        //            }
        //        }
        
        //        print(jsonResult.descriptionInStringsFileFormat)
        //        var ss = "\(jsonResult)"//.descriptionInStringsFileFormat;
        
        //let js = "window.postMessage(\(jsonResult.descriptionInStringsFileFormat), \"https://earn-your-screentime-settings.herokuapp.com\")"
        //        let js = "sendMessage(\"\(jsonResult.descriptionInStringsFileFormat)\")"//window.postMessage(\'\(ss)\', \"https://earn-your-screentime-settings.herokuapp.com\")"
        
        //        webview?.evaluateJavaScript(js,completionHandler: { (html: Any?, error: Error?) in
        //            print(html)
        //        })
        
        //        do {
        ////            let jsonData = try JSONSerialization.data(withJSONObject: jsonResult, options: [])  // serialize the data dictionary
        ////          let jsonEncodedData = jsonData.base64EncodedData()//([])   // base64 eencode the data dictionary
        //
        //
        //            print(stringjson)
        //             //ss = ss.replacingOccurrences(of: "\"", with: "\\\"")
        //            //ss = ss.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ss
        //
        //            //let javascript = "loadSettingsDataFromMac(\"{ram=shyam;}{sita=geeta}\");" //wor
        //            //let javascript = "loadSettingsDataFromMac(\"{ram = shyam;}\n{sita = geeta}\");"//not working
        //
        //        } catch let error as NSError {          print(error)
        //        }
        
    }
    override func viewWillAppear() {
        
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
    //        if let url = URL(string: "http://earnyourscreentime.com/settings-generator") {
    //            NSWorkspace.shared.open(url)
    //        }
    //    }earnyourscreentime.com/settings-generator
    
    //    Visit earnyourscreentime.com/settings-generator to generate settings
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
    @IBAction func btnSaveClicked(_ sender: Any) {

        isGettingSchema = true
        btnSave.isEnabled = false
//        btnCancel.isEnabled = false
        loader.startAnimation(self)
        getSchemsFile(completionHandler: {dic in
            DispatchQueue.main.async {
                isGettingSchema = false
                self.btnSave.isEnabled = true
//                self.btnCancel.isEnabled = true
                self.loader.stopAnimation(self)
                
                if dic == nil{
                    let alert = NSAlert()
                    alert.alertStyle = .informational
                    
                    var schemaError = "Your settings can not be validated."
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
                    var text = self.textViewJson.string.replacingOccurrences(of: "”", with: "\"")
                    text = text.replacingOccurrences(of: "“", with: "\"")
                    self.textViewJson.string = text
                    if let data = self.textViewJson.string.data(using: String.Encoding.utf8) {
                        
                        do {
                            let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])

                            let state = try JSONSchema.validate(jsonResult, schema: dic as! [String : Any])
                            
                            print(state)
                            if state.errors == nil{ 
                                UserDefaults.standard.set(self.textViewJson.string, forKey: kUserdefaultsSelectedJson)
                                appdelegate?.quitAndRestartApp()
                            }else{
                                print(state.errors)
                                let alert = NSAlert()
                                alert.alertStyle = .informational
                                
                                var settingIsNotValidText = "Sorry it seems like your settings aren’t valid. Please generate settings at earnyourscreentime.com/settings"
                                var buttonOkText = "OK"
                                if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                                    settingIsNotValidText = settings.value(forKey: "settingIsNotValidText") as? String ?? settingIsNotValidText
                                    buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                                }
                                
                                alert.messageText = settingIsNotValidText
                                if state.errors?.count != 0{
                                    alert.informativeText = state.errors?.first?.description ?? ""
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

                        } catch let error as NSError {
                            print(error)
                        }
                    }
                }
            }
        })
        
        
        
        
        
        
        //  } catch let error as NSError {
        //     print(error)
        // }
        //   }
        
        
    }
    
    func jsonReceivedFromWebView(jsonResult: NSDictionary){

        
        isGettingSchema = true
        
        getSchemsFile(completionHandler: {dic in
            DispatchQueue.main.async {
                isGettingSchema = false
                
                
                if dic == nil{
                    let alert = NSAlert()
                    alert.alertStyle = .informational
                    
                    var schemaError = "Your settings can not be validated."
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
                    
                    
                    
                    
                    
                    do{
                        let state = try JSONSchema.validate(jsonResult, schema: dic as! [String : Any])
                        print(state)
                        if state.errors == nil{
                            
                            
                            
                            let alert = NSAlert()
                            alert.alertStyle = .informational

                            var settingIsValidText = "Your settings have been validated and will be applied now."
                            var buttonOkText = "OK"
                            if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                                settingIsValidText = settings.value(forKey: "settingIsValidText") as? String ?? settingIsValidText
                                buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                            }

                            alert.messageText = settingIsValidText
                            alert.addButton(withTitle: buttonOkText)
                            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                   // self.setData()
                                    
                                    
                                    do {
                                        let jsonResultData =  try JSONSerialization.data(withJSONObject: jsonResult, options: JSONSerialization.WritingOptions.prettyPrinted)
                                        
                                        print(jsonResultData)
                                        
                                        if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                            print()
                                            UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                            appdelegate?.quitAndRestartApp()
                                        }
                                        
                                        
                                    } catch let myJSONError {
                                        print(myJSONError)
                                    }
                                    
                                    
                                    
                                }


                            })
                            
                            
                        }else{
                            print(state.errors)
                            let alert = NSAlert()
                            alert.alertStyle = .informational

                            var settingIsNotValidText = "Sorry it seems like your settings aren’t valid. Please generate settings at earnyourscreentime.com/settings"
                            var buttonOkText = "OK"
                            if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                                settingIsNotValidText = settings.value(forKey: "settingIsNotValidText") as? String ?? settingIsNotValidText
                                buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                            }

                            alert.messageText = settingIsNotValidText
                            if state.errors?.count != 0{
                                alert.informativeText = state.errors?.first?.description ?? ""
                            }

                            alert.addButton(withTitle: buttonOkText)

                            //let buttons = alertremoveitem.buttons
                            // alertremoveitem.beginSheetModal(for: self.window!, completionHandler: nil)
                            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                   // self.setData()
                                }


                            })

                        }
                    }catch{
                        
                    }

                }
            }
        })
        
        
        
        
        
        
        //  } catch let error as NSError {
        //     print(error)
        // }
        //   }
        
        
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
}
class MessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
        print("call back hua")
        
        
        if let data = (message.body as? String ?? "").data(using: String.Encoding.utf8) {
            
            do {
                let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                print(jsonResult)
                
                selectJsonVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
//                let alert = NSAlert()
//                alert.alertStyle = .informational
//                let buttonOkText = "OK"
//                alert.messageText = "Settings received but not implemented yet."
//                alert.addButton(withTitle: buttonOkText)
//
//                alert.beginSheetModal(for: selectJsonVcObj!.view.window!, completionHandler: { (modalResponse) in
//                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
//                    }
//
//
//                })
                
                
            }
            catch{
                
            }
        }
        
        
        //        if message.body as? String ?? "" == "setting_saved"{
        //            print("correct")
        //        }
        
    }
}

func makeWebView() -> WKWebView {
//    let preferences = WKPreferences()
//    preferences.javaScriptEnabled = true
    let handler = MessageHandler()
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(handler, name: "setting_saved")
    configuration.preferences.javaScriptEnabled = true// = preferences
    return WKWebView(frame: .zero, configuration: configuration)
}



