//
//  globalFile.swift
//  FBHelper
//
//  Created by Prashant Sawnani on 26/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

var isTestUser = false

let buttonTitleColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
let buttonBgColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
class Button: NSButton {
    var mouseDown = false
    
    let titleDisableColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    @IBInspectable var horizontalPadding   : CGFloat = 50
    @IBInspectable var verticalPadding    : CGFloat = 50
    
    @IBInspectable var isForPrefrences    : Bool = false
    
    var borderWidth: CGFloat = 1{
        didSet{
            self.layer?.borderWidth = borderWidth
        }
    }
    var currentTitle = ""
    var buttonColor = buttonBgColor.cgColor{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = NSColor.black//buttonTitleColor
            }else{
                self.layer?.backgroundColor = NSColor.clear.cgColor
                self.layer?.borderColor = NSColor.gray.cgColor
                self.titleColor = NSColor.gray///buttonTitleColor
            }
        }
    }
    
    override var isEnabled: Bool{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = NSColor.black//buttonTitleColor
            }else{
                self.layer?.backgroundColor = NSColor.clear.cgColor
                self.layer?.borderColor = NSColor.gray.cgColor
                self.titleColor = NSColor.gray//titleDisableColor//buttonTitleColor
            }
        }
    }
    var buttonDownColor = NSColor(red: 226/255, green: 203/255, blue: 177/255, alpha: 1).cgColor
    var titleColor = NSColor.black{//buttonTitleColor
        didSet{
            self.title = currentTitle
        }
    }
    var borderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1).cgColor
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        self.isBordered = false
        self.layer?.cornerRadius = self.frame.height/7
        self.layer?.backgroundColor = buttonColor
        
        self.layer?.borderWidth = borderWidth
        self.layer?.borderColor = borderColor
        self.contentTintColor = titleColor
    }
    
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        if self.image == nil{// if not an image button than
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }else{
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }
        return size;
    }
    override func draw(_ dirtyRect: NSRect) {
        let originalBounds = self.bounds
        defer { self.bounds = originalBounds }
        
        // Inset bounds by the image padding
        self.bounds = originalBounds.insetBy(
            dx: 10,
            dy: 0
        )
        //}
        // Draw the button content with padding
        super.draw(dirtyRect)
    }
    
    
    override var title: String {
        didSet {
            currentTitle = title
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            
            let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, .font:self.font ?? NSFont.systemFont(ofSize: 12)] as [NSAttributedString.Key : Any]
            let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
            self.attributedTitle = attrString
            // }
        }
    }
    
    
    
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = buttonDownColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                if isEnabled{// possible to be in disable state after mouse down
                    NSCursor.pointingHand.set()
                }
            }
            if isEnabled{// possible to be in disable state after mouse down
                self.layer?.backgroundColor = buttonColor
            }
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        if self.isEnabled{
            NSCursor.arrow.set()
            self.layer?.backgroundColor = buttonColor
        }
    }
}

// Suite name shared with the main app — must derive identically in both targets.
// The team prefix comes from the build's DEVELOPMENT_TEAM (via FBTeamIdentifierPrefix in
// Info.plist) so a contributor building under their own team still gets a matching suite.
let fbSharedDefaultsSuiteName: String = {
    if let team = Bundle.main.object(forInfoDictionaryKey: "FBTeamIdentifierPrefix") as? String, !team.isEmpty {
        return "\(team).group.com.focusbear.fbmac"
    }
    return "TCUD568B3U.group.com.focusbear.fbmac"
}()

let sharedDefaults = UserDefaults(suiteName: fbSharedDefaultsSuiteName)
let kUserdefaultsAppQuitForUser = "kUserdefaultsAppQuitForUser"
let kUserdefaultsStartHabitNagCount = "kUserdefaultsStartHabitNagCount"
let kUserdefaultsLastNagShowDate = "kUserdefaultsLastNagShowDate"
let kUserdefaultsDontShowNudgeView = "kUserdefaultsDontShowNudgeView"
let kUserdefaultsNoHabitFound = "kUserdefaultsNoHabitFound"
let kUserdefaultsOnboardingIncompleted = "kUserdefaultsOnboardingIncompleted"

var kUserdefaultsStartMainAppIfNotRunning = "kUserdefaultsStartMainAppIfNotRunning"

// #2575: a Date written by the main app (scheduleMainAppRestart). When set, this helper relaunches the
// main app once the time passes, then clears it. Must match the constant in FocusBear/allUserdefaults.swift.
let kUserdefaultsMainAppScheduledRestartDate = "kUserdefaultsMainAppScheduledRestartDate"

let appdelegate = NSApplication.shared.delegate as? AppDelegate




let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)

var nudgeVcObj:nudgeVc?
func getNudgeVcObject()->nudgeVc{
    if nudgeVcObj == nil{
        nudgeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("nudgeVc")) as? nudgeVc
    }
    return nudgeVcObj!
}


var nudgeWcObj:nudgeWc?
func getNudgeWcObject()->nudgeWc{
    if nudgeWcObj == nil{
        nudgeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("nudgeWc")) as? nudgeWc
    }
    return nudgeWcObj!
}

func showNudgeWindow(day:Int){
    addLog(text: "showNudgeWindow")
    getNudgeWcObject().contentViewController = getNudgeVcObject()
    getNudgeWcObject().showWindow(nil)
    nudgeVcObj?.resetData(dayCount: day)
//    NSApp.activate(ignoringOtherApps: true)
    NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
}

var DebugLogsURL:URL?
let isDebugModeEnabled = false
func addLog(text:String){
    if isDebugModeEnabled{
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = df.string(from: Date())
        
        print(now , " - ", text, to: &Log.log)
    }
    print(text)
}
class Log: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        
        if let log = DebugLogsURL{//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
}
//******************************************CreateDirectoryIfNotExist*******************************************************//
func CreateDirectoryIfNotExist(path:String){
    if !FileManager.default.fileExists(atPath: path){
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }catch{
            
        }
    }
}




//var appVersion = ""
var macOSVersion = ""

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

/// Queues the event for the main app to send to `/events`: FBHelper holds no credentials.
func captureEventEndpoint(event: String, metadata: [String: Any]) {
    guard let sharedDefaults,
          let userId = sharedDefaults.object(forKey: kUserdefaultsSharedUserId) as? String else {
        addLog(text: "captureEventEndpoint skipped \(event): no user id")
        return
    }
    HelperEventQueue(defaults: sharedDefaults).enqueue(event: event, metadata: metadata, userId: userId)
    addLog(text: "captureEventEndpoint queued \(event)")
}

func capturePosthog(event:String, metadata:[String:Any]){
    let isInternalTestUser = sharedDefaults.map(InternalTestUser.isRecorded(in:)) ?? false
    if isInternalTestUser || isTestUser {
        return
    }
    
    captureEventEndpoint(event: event, metadata: metadata)
    
    
    addLog(text: "capturePosthog event: \(event)")
    
    let responsePath = "https://app.posthog.com/capture/"
    if let responsePathUrl = NSURL(string: responsePath){
        
        //addLog(text: "api call capture \(responsePathUrl)")
        let request = NSMutableURLRequest(url:responsePathUrl as URL);
        request.httpMethod = "POST";
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        var distinct_id = ""
        if let userId = sharedDefaults?.object(forKey: kUserdefaultsSharedUserId) as? String {
            distinct_id = userId
        }else{
            return;
        }
        
        
        var properties = [String:Any]()
        
        properties["distinct_id"] = distinct_id
        properties["appVersion"] = sharedDefaults?.object(forKey: kUserdefaultsSharedAppVersion) as? String ?? ""
        properties["macOSVersion"] = macOSVersion
        properties["USES_MAC_APP"] = true

        for key in metadata.keys{
            properties[key] = metadata[key]
        }
        
        var json: [String: Any] = [
            "api_key": "phc_Y6hD2dvO1zylm7CLij5CuNt6S5gTxe7EVXoxZcb2xUm",
            "event": event,
            "context": [
                "os": "MacOS",
                "osVersion": macOSVersion,
                "appVersion": sharedDefaults?.object(forKey: kUserdefaultsSharedAppVersion) as? String ?? ""
            ],
            "properties": properties
        ]
        
        if sharedDefaults?.object(forKey: kUserdefaultsSharedIsPurchased) as? Bool == true{
            json["isPayingUser"] = true
        }else{
            json["isPayingUser"] = false
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse{
                if httpResponse.statusCode == 200{ //success
                    //   addLog(text: "api call capturePosthog success")
                    print("api call capturePosthog success")
                    return;
                }else{
                    addLog(text: "api call capturePosthog error:- statusCode is \(httpResponse.statusCode)")
//                    self.writeJsonInLog(data: data)
                    return
                }
            }
            if error != nil {
                addLog(text: "api call capturePosthog error: \(error!.localizedDescription)")
                return
            }
            
            return
        }
        
        task.resume()
    }else{
        
        return
    }
}







//func getConfigFile(fileUrl:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
//    addLog(text: "func call:- downloading config file")
//    if let responsePathUrl = NSURL(string: fileUrl){
//        addLog(text: "api call getConfigFile \(responsePathUrl)")
//        let request = NSMutableURLRequest(url:responsePathUrl as URL);
//        request.httpMethod = "GET";
//
//        let task = URLSession.shared.dataTask(with: request as URLRequest) {
//            data, response, error in
//
//            if let httpResponse = response as? HTTPURLResponse {
//                if httpResponse.statusCode == 200{
//
//                    if data != nil{
//
//                        //                    let responseStrInISOLatin = String(data: data!, encoding: String.Encoding.isoLatin1)
//                        //                    guard let modifiedDataInUTF8Format = responseStrInISOLatin?.data(using: String.Encoding.utf8) else {
//                        //                        print("could not convert data to UTF-8 format")
//                        //                        addLog(text: "error config file: could not convert data to UTF-8 format")
//                        //                        completionHandler(nil)
//                        //                        return
//                        //                    }
//                        //
//                        //
//                        //                    do {
//                        //                        let jsonResult = try JSONSerialization.jsonObject(with: modifiedDataInUTF8Format) as? NSDictionary
//                        //                        print(jsonResult)
//                        //                        completionHandler(jsonResult)
//                        //                        return
//                        //                    } catch {
//                        //                        print(error)
//                        //                        addLog(text: "error config file: \(error.localizedDescription)")
//                        //                        completionHandler(nil)
//                        //                        return
//                        //                    }
//
//                        do {
//                            if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//
//                                print(jsonResult)
//                                addLog(text: "api call getConfigFile return success")
//                                completionHandler(jsonResult)
//                                return
//                            }
//
//                        }catch{
//                            print(error)
//                            addLog(text: "error reading config file: \(error.localizedDescription)")
//                            completionHandler(nil)
//                            return
//                        }
//
//                    }
//
//                    completionHandler(nil)
//                    return
//                }else{
//                    addLog(text: "api call getConfigFile Api error:- statusCode is \(httpResponse.statusCode)")
////                    self.writeJsonInLog(data: data)
//                    completionHandler(nil)
//                    return
//                }
//            }
//            if error != nil {
//                addLog(text: "error config file: \(error!.localizedDescription)")
//                completionHandler(nil)
//                return
//            }
//            completionHandler(nil)
//            return
//        }
//        task.resume()
//    }else{
//        completionHandler(nil)
//    }
//}



var configjson = NSDictionary()

