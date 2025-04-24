//
//  brainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class brainDumpVc: NSViewController, NSTextViewDelegate {
    
    
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
//    @IBOutlet weak var lblTimeRemaining: NSTextField!
//    @IBOutlet weak var lblTitleTimeRemaining: NSTextField!
//    @IBOutlet var textViewIntention: NSTextView!
//    @IBOutlet weak var lblTitleIntention: NSTextField!
    
//    var timer:Timer?
    
    
    var titleWorkNoteFirst = "Things I'll do in my next break:"
    var titleWorkNoteSecond = "Things you wanted to do in your break:"
    var titleTimeRemainingText = "Time remaining:"
    var titleTimeSpentText = "Time spent:"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblNotesSaveInfo.stringValue = "Your notes will automatically save"
        btnSave.title = "Close"
//        btnStartFocus.title = "Start Focus"
        
        lblTitleOpenUrl.stringValue = "Open Url:"
        btnOpenUrl.title = "Go"
//        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                if let buttonStartFocusText = startingFocusModeInfo.value(forKey: "buttonStartFocusText") as? String{
//                    btnStartFocus.title = buttonStartFocusText
//                }
//            }
//        }
//        lblTitleIntention.stringValue = "Intention:"
//        lblTitleTimeRemaining.stringValue = "Time remaining:"
        lblTitleWorkNote.stringValue = "Dump down ideas you have so you don't forget - anything you write here will remain forever unless you delete it"
        
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//            lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
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
//        lblTitleTimeRemaining.stringValue = titleTimeRemainingText
//        textViewIntention.delegate = self
        textViewWorkNote.delegate = self
        
        let webViewConfiguration = WKWebViewConfiguration()
        let newWebView = WKWebView(frame: CGRect.zero, configuration: webViewConfiguration)
        let userAgent = newWebView.stringByEvaluatingJavaScript(from: "navigator.userAgent")! + " Version/15.2 Safari/605.1.15"
        
        webView.customUserAgent = userAgent
    }
    override func viewWillAppear() {
        
        if isFocusModeOn() || isAnyAllowedFocusModeActivityRunning{
//            startRefreshRemainingTimer()
//            textViewIntention.isEditable = true
//            textViewIntention.enclosingScrollView?.isHidden = false
//            btnStartFocus.isHidden = true
//            lblTitleIntention.stringValue = "Intention:"
//            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
//            }
//            lineTopSpace.constant = 66
        }else if isFocusModePaused(){
//            startRefreshRemainingTimer()
//            textViewIntention.isEditable = true
//            textViewIntention.enclosingScrollView?.isHidden = false
//            btnStartFocus.isHidden = true
//            lblTitleIntention.stringValue = "Intention:"
//            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
//            }
//            lineTopSpace.constant = 66
        }else{
//            lblTimeRemaining.stringValue = "0"
//            textViewIntention.isEditable = false
//            textViewIntention.isSelectable = false
//            textViewIntention.enclosingScrollView?.isHidden = true
//            btnStartFocus.isHidden = false
//            lblTitleIntention.stringValue = "You're currently not in a focus session"
//            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleNotFocusSession") as? String ?? lblTitleIntention.stringValue
//            }
//            lineTopSpace.constant = 50
        }
//        brainDumpVcObj?.textViewIntention.isEditable = true
//        if textViewIntention.enclosingScrollView?.isHidden == false{
//            textViewIntention.string = whatToAchieveInFocusBlock
//            if whatToAchieveInFocusBlock.isEmpty{
//                if !focusModeTaskStringIsEmpty(){
//                    textViewIntention.string = getFocusModeTaskString()
//                    brainDumpVcObj?.textViewIntention.isEditable = false
//                }
//            }
//        }
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            textViewWorkNote.string = notes
        }else{
            textViewWorkNote.string = ""
        }
        resetData()
    }
    
    override func viewWillDisappear() {
//        timer?.invalidate()
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
            
            
            
            if isFocusModeOn() || isAnyAllowedFocusModeActivityRunning{
//                textViewIntention.enclosingScrollView?.isHidden = true
//                lblTitleIntention.stringValue = ""
//                lineTopSpace.constant = -20
            }else{
//                lblTitleIntention.stringValue = "You're currently not in a focus session"
                if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                    lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleNotFocusSession") as? String ?? lblTitleIntention.stringValue
                }
//                lineTopSpace.constant = 50
            }
        }else{
            boxBrainDumpWebView.isHidden = true
            stackViewBrainDumpWorkNote.isHidden = false
            btnLinkSettingBrainDump.title = "Use your own system for brain dump"
            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                btnLinkSettingBrainDump.title = brainDumpVcInfo.value(forKey: "buttonOwnUrlBrainDumpText") as? String ?? btnLinkSettingBrainDump.title
            }
            lblNotesSaveInfo.isHidden = false
            if isFocusModeOn() || isAnyAllowedFocusModeActivityRunning{
//                lineTopSpace.constant = 66
//                textViewIntention.enclosingScrollView?.isHidden = false
//                lblTitleIntention.stringValue = "Intention:"
                if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                    lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
                }
            }else{
//                lblTitleIntention.stringValue = "You're currently not in a focus session"
                if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                    lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleNotFocusSession") as? String ?? lblTitleIntention.stringValue
                }
//                lineTopSpace.constant = 50
            }
        }
    }
    
    func loadWebView(){
        let url = SettingsManagerObject.brainDumpCustomUrlValue
        if let link = URL(string:url){
            let request = URLRequest(url: link)
            self.webView.load(request)
        }
    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
//        if textView == self.textViewIntention{
//            whatToAchieveInFocusBlock = textView.string
//            if taskPlayerWcObj != nil{
//                if taskPlayerWcObj?.window?.isVisible ?? false{
//                    taskPlayerVcObj?.updateIntentionToPlayer()
//                }
//            }
//        }else
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
//        startRefreshRemainingTimer()
//        textViewIntention.isEditable = true
//        btnStartFocus.isHidden = true

        if SettingsManagerObject.brainDumpCustomUrlEnabled{
//            textViewIntention.enclosingScrollView?.isHidden = true
//            lblTitleIntention.stringValue = ""
//            lineTopSpace.constant = -20
        }else{
//            lineTopSpace.constant = 66
//            textViewIntention.enclosingScrollView?.isHidden = false
//            lblTitleIntention.stringValue = "Intention:"
//            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
//            }
        }
    }
    func focusModeFinished(){
//        brainDumpVcObj?.textViewIntention.isEditable = true
//        lblTimeRemaining.stringValue = "0"
//        timer?.invalidate()
//        timer = nil
//        textViewIntention.isEditable = false
//        textViewIntention.isSelectable = false
//        textViewIntention.enclosingScrollView?.isHidden = true
//        btnStartFocus.isHidden = false
//        lblTitleIntention.stringValue = "You're currently not in a focus session"
//        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//            lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleNotFocusSession") as? String ?? lblTitleIntention.stringValue
//        }
//        lineTopSpace.constant = 50
    }
    func breakStarted(){
        //        lblTitleWorkNote.stringValue = titleWorkNoteSecond
    }
//    func setRemainingTime(){
//        if isFocusModePaused(){
//            let secondsBetween = appdelegate!.remainingFocusModeSecondsAfterPaused
//            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
//            var hour = "\(h)"
//            var minute = "\(m)"
//            var second = "\(s)"
//
//            if hour.count == 1 {
//                hour = "0\(h)"
//            }
//
//            if minute.count == 1 {
//                minute = "0\(m)"
//            }
//            if second.count == 1 {
//                second = "0\(s)"
//            }
//
//            DispatchQueue.main.async {
//                if h == 0{
//                    self.lblTimeRemaining.stringValue = "\(minute):\(second)"
//                }else{
//                    self.lblTimeRemaining.stringValue = "\(hour):\(minute):\(second)"
//                }
//            }
//        }else{
//            if let date = endFocusModeTime{
//
//                var secondsBetween: TimeInterval = 0
//
//                if timerForFocusMode != nil{
//                    lblTitleTimeRemaining.stringValue = titleTimeRemainingText
//                    secondsBetween = date.timeIntervalSince(Date())
//                }else{
//                    lblTitleTimeRemaining.stringValue = titleTimeSpentText
//                    if startFocusModeTime != nil{
//                        secondsBetween = Date().timeIntervalSince(startFocusModeTime!)
//                    }
//                }
//                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
//                var hour = "\(h)"
//                var minute = "\(m)"
//                var second = "\(s)"
//
//                if hour.count == 1 {
//                    hour = "0\(h)"
//                }
//
//                if minute.count == 1 {
//                    minute = "0\(m)"
//                }
//                if second.count == 1 {
//                    second = "0\(s)"
//                }
//
//                DispatchQueue.main.async {
//                    if h == 0{
//                        self.lblTimeRemaining.stringValue = "\(minute):\(second)"
//                    }else{
//                        self.lblTimeRemaining.stringValue = "\(hour):\(minute):\(second)"
//                    }
//                }
//
//            }else{
//                if !isAnyAllowedFocusModeActivityRunning{
//                    lblTimeRemaining.stringValue = "0"
//                    focusModeFinished()
//                }else{
//                    lblTimeRemaining.stringValue = timerViewcontrollerObj?.lblTimer.stringValue ?? ""
//                }
//            }
//        }
//
//    }
    
//    func startRefreshRemainingTimer() {
//        if timer != nil{
//            timer?.invalidate()
//            timer = nil
////            lblTimeRemaining.stringValue = "0"
//        }
//        setRemainingTime()
//        DispatchQueue.main.async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
//        }
//    }
    
//    @objc func performTimerCount() {
//        if !isFocusModeOn() && !isAnyAllowedFocusModeActivityRunning{
//            self.setRemainingTime()
//            timer?.invalidate()
//        }
//        DispatchQueue.main.async {
//            self.setRemainingTime()
//        }
//    }
    
    @IBAction func btnSaveClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
//    @IBAction func btnStartFocusClicked(_ sender: Any) {
//        if isPurchased == false && daysLeft <= 0{
//            if trialExpiredNagWcObj != nil{
//                if trialExpiredNagWcObj?.window?.isVisible ?? false{
//                    return;
//                }
//            }
//            showUpgradeNowWindow()
//            return;
//        }
//        if isHardCorePomodoroModeOn{
//            let alert = NSAlert()
//            alert.setSharingType()
//            alert.messageText = "You can not start a focus mode while Super Pomodoro session is running."
//            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                    alert.messageText = startingFocusModeInfo.value(forKey: "pomodoroRunningCantStartFocusText") as? String ?? alert.messageText
//                }
//            }
//            NSApplication.shared.activate(ignoringOtherApps: true)
//            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
//            return;
//        }else{
//            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
//                let alert = NSAlert()
//                alert.setSharingType()
//                alert.messageText = "You can not start a focus mode while an activity is running."
//
//                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                    if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                        alert.messageText = startingFocusModeInfo.value(forKey: "activityRunningCantStartFocusText") as? String ?? alert.messageText
//                    }
//                }
//                NSApplication.shared.activate(ignoringOtherApps: true)
//                alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
//                return;
//            }
//        }
//        appdelegate?.menuShowPomodoroModeView()
//    }
    
    @IBAction func btnLinkSettingBrainDumpClicked(_ sender: Any) {
//        toDoListSettingsVcObj
        
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
        SettingsManagerObject.brainDumpCustomUrlValue = textFieldOpenUrl.stringValue
        SettingsManagerObject.isSettingsChanged = true
        resetData()
        if toDoListSettingsVcObj != nil{
            if toDoListSettingsVcObj?.isViewVisible ?? false{
                toDoListSettingsVcObj?.reloadSettingsForBrainDump()
            }
        }
    }
    
}

