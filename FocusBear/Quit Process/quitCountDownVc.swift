//
//  quitProcessVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/04/22.
//  ve
//

import Cocoa

class quitCountDownVc: NSViewController {
    
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSeconds: NSTextField!
    @IBOutlet weak var lblSubtile: NSTextField!
    @IBOutlet weak var lblMessage: NSTextField!
    
    @IBOutlet weak var btnCancelAbort: NSButton!
    @IBOutlet weak var lblEmailId: NSTextField!
    @IBOutlet weak var lblPleaseEmail: NSTextField!
    var currentTimer = 0
    var totalDuration = 10
    var timer:Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        
        lblEmailId.stringValue = emailID
        if let abortInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingTitle = abortInfo.value(forKey: "quittingTitle") as? String{
                lblTitle.stringValue = quittingTitle
            }else{
                lblTitle.stringValue = "Quitting.."
            }
            if let quittingCountDownInfo = abortInfo.value(forKey: "quittingCountDownInfo") as? NSDictionary{
                if let subTitle = quittingCountDownInfo.value(forKey: "subTitle") as? String{
                    lblSubtile.stringValue = subTitle
                }else{
                    lblSubtile.stringValue = "Are you sure you want to give up on your habits? Please take 10 seconds to reflect on whether you are serious about quitting."
                }
                
                if let message = quittingCountDownInfo.value(forKey: "message") as? String{
                    lblMessage.stringValue = message
                }else{
                    lblMessage.stringValue = "While you wait, reflect on why you’re doing this. If it was because your morning routine was too ambitious, perhaps scale it back to only be a few minutes long so that it’s easier to do it than not do it. If you’re aborting because the app is broken, really sorry!!"
                }
                
                if let pleaseEmailText = quittingCountDownInfo.value(forKey: "pleaseEmailText") as? String{
                    lblPleaseEmail.stringValue = pleaseEmailText
                }else{
                   lblPleaseEmail.stringValue = "Please email"
                }
                if let buttonQuitCancelText = quittingCountDownInfo.value(forKey: "buttonQuitCancelText") as? String{
                    btnCancelAbort.title = buttonQuitCancelText
                }else{
                    btnCancelAbort.title = "I didn’t mean it. Let me do my habits!"
                }
            }
            
        }
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Crying_small")
            imgViewGif.animates = true
        }
    }
    var enterPasswordVcObj: enterPasswordVc?
    func resetData(){
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.enterPasswordVcObj == nil{
                self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
            }
            self.view.addSubview(self.enterPasswordVcObj!.view)
            self.view.addConstraints(subView: self.enterPasswordVcObj!.view)
            addLog(text: "Showing enter password view from quit")
            currentTimer = 0
            totalDuration = 10
            let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
            var minute = "\(m)"
            var second = "\(s)"
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }
            self.lblSeconds.stringValue = "\(minute):\(second)"
        }else{
            startTimer()
        }
    }
    
    func startTimer() {
        currentTimer = 0
        totalDuration = 10
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblSeconds.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            print("xxxxx")
        }
    }
    
    @objc func performTimerCount() {
        
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblSeconds.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    getQuittingWindowObject().contentViewController = getQuittingConfirmVcObject()
                    getQuittingConfirmVcObject().resetData()
                }
            }
        }
    }
    
    
    @IBAction func btnEmaiClicked(_ sender: Any) {
    }
    @IBAction func btnCancelAbortClicked(_ sender: Any) {
        addLog(text: "quitCountDownVc - btnCancelAbortClicked")//
        self.timer?.invalidate()
        self.timer = nil
        self.view.window?.close()
    }
}
