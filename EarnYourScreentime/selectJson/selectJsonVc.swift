//
//  selectJsonVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 05/01/22.
//  .
//

import Cocoa
import JSONSchema
class selectJsonVc: NSViewController, NSTextViewDelegate {
    
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var lblVisitUrl: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnSave: cursorButton!
    @IBOutlet var textViewJson: NSTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        textViewJson.delegate = self
        textViewJson.font = NSFont(name: btnSave!.font?.familyName ?? "", size: 14)
        lblTitle.stringValue = "Enter settings JSON below:"
        lblVisitUrl.stringValue = "Visit earnyourscreentime.com/settings-generator to generate settings"
        btnCancel.stringValue = buttonCancelText
        btnSave.title = "Save"
        
        
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            if let title = settings.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let buttonSaveText = settings.value(forKey: "buttonSaveText") as? String{
                btnSave.title = buttonSaveText
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
        btnCancel.isEnabled = false
        loader.startAnimation(self)
        getSchemsFile(completionHandler: {dic in
            DispatchQueue.main.async {
                isGettingSchema = false
                self.btnSave.isEnabled = true
                self.btnCancel.isEnabled = true
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
