//
//  brainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class brainDumpVc: NSViewController, NSTextViewDelegate{
    
    @IBOutlet weak var lblTimeSinceLastBreak: NSTextField!
    @IBOutlet weak var btnOpenUrl: Button!
    @IBOutlet weak var textFieldOpenUrl: NSTextField!
    @IBOutlet weak var lblTitleOpenUrl: NSTextField!
    @IBOutlet weak var boxBrainDumpWebView: NSBox!
    @IBOutlet weak var stackViewBrainDumpWorkNote: NSStackView!
    @IBOutlet weak var btnLinkSettingBrainDump: underLineButton!
    @IBOutlet weak var scrollViewWorkNote: NSScrollView!
    @IBOutlet weak var webView: WKWebView!
//    @IBOutlet weak var btnStartFocus: Button!
    @IBOutlet weak var lblNotesSaveInfo: NSTextField!
    @IBOutlet weak var btnSave: Button!
//    @IBOutlet weak var lineTopSpace: NSLayoutConstraint!
    @IBOutlet var textViewWorkNote: NSTextView!
    @IBOutlet weak var lblTitleWorkNote: NSTextField!
    
    
    var titleWorkNoteFirst = "Things I'll do in my next break:"
    var titleWorkNoteSecond = "Things you wanted to do in your break:"
    var titleTimeRemainingText = "Time remaining:"
    var titleTimeSpentText = "Time spent:"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblNotesSaveInfo.stringValue = "Your notes will automatically save"
        btnSave.title = "Close"
        lblTitleOpenUrl.stringValue = "Open Url:"
        btnOpenUrl.title = "Go"
        lblTitleWorkNote.stringValue = "Dump down ideas you have so you don't forget - anything you write here will remain forever unless you delete it"
        
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
            titleWorkNoteFirst = brainDumpVcInfo.value(forKey: "titleWorkNoteFirst") as? String ?? titleWorkNoteFirst
            titleWorkNoteSecond = brainDumpVcInfo.value(forKey: "titleWorkNoteSecond") as? String ?? titleWorkNoteSecond
            lblTitleWorkNote.stringValue = brainDumpVcInfo.value(forKey: "writeThingsHereText") as? String ?? lblTitleWorkNote.stringValue
            titleTimeSpentText = brainDumpVcInfo.value(forKey: "titleTimeSpentText") as? String ?? titleTimeSpentText
            lblNotesSaveInfo.stringValue = brainDumpVcInfo.value(forKey: "notesSaveInfoText") as? String ?? lblNotesSaveInfo.stringValue
            btnSave.title = brainDumpVcInfo.value(forKey: "buttonCloseText") as? String ?? btnSave.title
            lblTitleOpenUrl.stringValue = brainDumpVcInfo.value(forKey: "titleOpenUrl") as? String ?? lblTitleOpenUrl.stringValue
            btnOpenUrl.title = brainDumpVcInfo.value(forKey: "buttonOpenUrlText") as? String ?? btnOpenUrl.title
        }
        textViewWorkNote.delegate = self
        
        let webViewConfiguration = WKWebViewConfiguration()
        let newWebView = WKWebView(frame: CGRect.zero, configuration: webViewConfiguration)
        let userAgent = newWebView.stringByEvaluatingJavaScript(from: "navigator.userAgent")! + " Version/15.2 Safari/605.1.15"
        
        webView.customUserAgent = userAgent
        webView.navigationDelegate = self
    }
    override func viewWillAppear() {
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            textViewWorkNote.string = notes
        }else{
            textViewWorkNote.string = ""
        }
        resetData()
    }
    
    
    func resetData(){
        if SettingsManagerObject.brainDumpCustomUrlEnabled{
            boxBrainDumpWebView.isHidden = false
            stackViewBrainDumpWorkNote.isHidden = true
            let url = SettingsManagerObject.brainDumpCustomUrlValue
            textFieldOpenUrl.stringValue = url
            btnLinkSettingBrainDump.title = "← Back to basic brain dump"
            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                btnLinkSettingBrainDump.title = brainDumpVcInfo.value(forKey: "buttonStartBasicBrainDumpText") as? String ?? btnLinkSettingBrainDump.title
            }
            loadWebView()
            lblNotesSaveInfo.isHidden = true
        }else{
            boxBrainDumpWebView.isHidden = true
            stackViewBrainDumpWorkNote.isHidden = false
            btnLinkSettingBrainDump.title = "Use your own system for brain dump"
            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                btnLinkSettingBrainDump.title = brainDumpVcInfo.value(forKey: "buttonOwnUrlBrainDumpText") as? String ?? btnLinkSettingBrainDump.title
            }
            lblNotesSaveInfo.isHidden = false
        }
    }
    
    func loadWebView(){
        let url = SettingsManagerObject.brainDumpCustomUrlValue
        if let link = URL(string:url){
            let request = URLRequest(url: link)
            self.webView.load(request)
        }
    }
    
    func checkCurrentUrl(){
        if let url = webView.url{
            let urlString = url.absoluteString
            for turl in appdelegate!.defaultAllowedUrl{
                if urlString.contains(turl){
                    return;
                }
            }
            let arrBlockedUrls = getBlockedUrlsToBlock()
            for turl in arrBlockedUrls{
                //Change all suggested blocked apps in onboarding to start with https:// #1233
                let bool = appdelegate!.validation.isUrlAlwaysBlocked(urlToCheck: urlString, blockedUrl: turl)
                if bool{
                    blockCurrentUrl(isAlwaysBlock:true, oldUrl: urlString)
                    return;
                }
            }
            
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
                for turl in arrBlockedUrlsForFocus{
                    let isBlocked = appdelegate!.validation.isUrlValid(urlToCheck: urlString, allowUrl: turl)
                    if isBlocked{
                        blockCurrentUrl(isAlwaysBlock:false, oldUrl: urlString)
                        return;
                    }
                }
            }
        }
    }
//    \(blockWebUrlString)?old_url=https%3A%2F%2Fwww.facebook.com&block_type=always-blocked
    func blockCurrentUrl(isAlwaysBlock:Bool, oldUrl:String){
        let oldUrl = oldUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? oldUrl
        if isAlwaysBlock{
            if let link = URL(string:"\(blockWebUrlString)?old_url=\(oldUrl)&block_type=always-blocked&braindump=true"){
                let request = URLRequest(url: link)
                self.webView.load(request)
            }
        }else{
            var stringTime = ""
            var focusMode = ""
            if isFocusModeRunning{
                for dic in arrFocusType{
                    if dic["isOn"] as? Bool == true{
                        focusMode = dic["name"] as? String ?? ""
                        break;
                    }
                }
                
                if let date = endFocusModeTime{
                    stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                }
                
                if let link = URL(string:"\(blockWebUrlString)?old_url=\(oldUrl)&focus_mode_end_time=\(stringTime)&focus_mode=\(focusMode)&braindump=true"){
                    let request = URLRequest(url: link)
                    self.webView.load(request)
                }
            }else{
                var blockType = ""
                if currentState == ._ACTIVITY_{
                    if currentActivityPlaying != nil{
                      //  activityAllowUrls = currentActivityPlaying!.allowUrls
                    }
                    blockType = "break-activity"
                }else if currentState == ._MORNING_HABIT_{
                    if currentHabitPlaying != nil{
                      //  activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "morning-habit"
                }else if currentState == ._EVENING_HABIT_{
                    if currentHabitPlaying != nil{
                        //activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "evening-habit"
                }else if currentState == ._SPECIAL_ACTIVITY_{
                    if currentHabitPlaying != nil{
                       // activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "special-activity"
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if currentHabitPlaying != nil{
                        //activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "custom-routine"
                }
                
                if let link = URL(string:"\(blockWebUrlString)?old_url=\(oldUrl)&block_type=\(blockType)&braindump=true"){
                    let request = URLRequest(url: link)
                    self.webView.load(request)
                }
            }
        }
    }
  
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == textViewWorkNote{
            UserDefaults.standard.set(textViewWorkNote.string, forKey: kUserdefaultsFocusModeNotes)
            if taskPlayerWcObj != nil{
                if taskPlayerWcObj?.window?.isVisible ?? false{
                    taskPlayerVcObj?.updateBrainDumpToPlayer()
                }
            }
        }
    }
    
    func focusModeStarted(){
        if SettingsManagerObject.brainDumpCustomUrlEnabled{
            
        }else{
            
        }
    }
    
    func focusModeFinished(){
        loadWebView()
    }
    
    func breakStarted(){
        //        lblTitleWorkNote.stringValue = titleWorkNoteSecond
    }

    @IBAction func btnSaveClicked(_ sender: Any) {
        self.view.window?.close()
    }

    @IBAction func btnLinkSettingBrainDumpClicked(_ sender: Any) {
        if SettingsManagerObject.brainDumpCustomUrlEnabled{
            SettingsManagerObject.brainDumpCustomUrlEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-specific-url-for-brain-dump", metadata: [:])
        }else{
            SettingsManagerObject.brainDumpCustomUrlEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-enable-specific-url-for-brain-dump", metadata: [:])
        }
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        resetData()
        if toDoListSettingsVcObj != nil{
            if toDoListSettingsVcObj?.isViewVisible ?? false{
                toDoListSettingsVcObj?.reloadSettingsForBrainDump()
            }
        }
    }
    
    @IBAction func btnOpenUrlClicked(_ sender: Any) {
        var urlString =  textFieldOpenUrl.stringValue.lowercased()
        if !urlString.contains("http://") && !urlString.contains("https://"){
            urlString = "https://" + urlString
            textFieldOpenUrl.stringValue = urlString
        }
        
        SettingsManagerObject.brainDumpCustomUrlValue = urlString
        SettingsManagerObject.isSettingsChanged = true
        resetData()
        if toDoListSettingsVcObj != nil{
            if toDoListSettingsVcObj?.isViewVisible ?? false{
                toDoListSettingsVcObj?.reloadSettingsForBrainDump()
            }
        }
    }
    
}


extension brainDumpVc: WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.checkCurrentUrl()
            }
        }
    }
}

