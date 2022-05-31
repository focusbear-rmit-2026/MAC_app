//
//  shutOffTimeVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 06/01/22.
//  
//

import Cocoa

class shutOffTimeVc: NSViewController {
    
    @IBOutlet weak var titleCenter: NSLayoutConstraint!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var lbltimer: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var lbl2: NSTextField!
    @IBOutlet weak var btnUnlock: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var btnGetAccessNow: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var step = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        resetView()
    }
    func resetView(){
        titleCenter.constant = 80

        if kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Yawn_small")
            imgViewGif.animates = true
        }
        
        lblTitle.stringValue = "Time to wind down"
        btnGetAccessNow.title = "Get access now"
        
        var shutOffHour = "\(shutOffTime?.hour ?? 0)"
        if shutOffHour.count == 1{
            shutOffHour = "0\(shutOffHour)"
        }
        
        var shutOffMinute = "\(shutOffTime?.minute ?? 0)"
        if shutOffMinute.count == 1{
            shutOffMinute = "0\(shutOffMinute)"
        }
        
        var startTimeHour = "\(startTime?.hour ?? 0)"
        if startTimeHour.count == 1{
            startTimeHour = "0\(startTimeHour)"
        }
        
        var startTimeMinute = "\(startTime?.minute ?? 0)"
        if startTimeMinute.count == 1{
            startTimeMinute = "0\(startTimeMinute)"
        }
        
        
        lblSubTitle.stringValue = "You told me you wanted to stay off your computer from \(shutOffHour):\(shutOffMinute) to \(startTimeHour):\(startTimeMinute). Enjoy your evening and sleep well. Look forward to helping you with your morning routine tomorrow."
        
        
        
        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
            if let title = shutOffTimeInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if var subTitle = shutOffTimeInfo.value(forKey: "subTitle") as? String{
                subTitle = subTitle.replacingOccurrences(of: "<SHUTOFFTIME>", with: "\(shutOffHour):\(shutOffMinute)")
                subTitle = subTitle.replacingOccurrences(of: "<STARTTIME>", with: "\(startTimeHour):\(startTimeMinute)")
                lblSubTitle.stringValue = subTitle
            }
            if let buttonAbortText = shutOffTimeInfo.value(forKey: "buttonAbortText") as? String{
                btnGetAccessNow.title = buttonAbortText
            }
        }
        
        lbl2.isHidden = true
        scrollView.isHidden = true
        btnUnlock.isHidden = true
        btnGetAccessNow.isHidden = false
        lbltimer.isHidden = true
        step = 0
    }
    @IBAction func btnGetAccessNowClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
            mainViewControllerObj!.showPasswordView()
        }else{
            getAccessNowClicked()
        }
    }
    
    
    func getAccessNowClicked(){
        titleCenter.constant = 0
        btnGetAccessNow.isHidden = true
        scrollView.isHidden = false
        lbl2.isHidden = false
        lbltimer.isHidden = false
        btnUnlock.isHidden = false
        
        lblTitle.stringValue = "Emergency?"
        lblSubTitle.stringValue = "Are you sure you want to do this? Using your computer late at night could mess up your sleep. Please take 30 seconds to reflect on whether this is really an emergency or whether it can wait."
        lbl2.stringValue = "Feel free to write an explanation here:"
        btnUnlock.title = "Cancel"
        
        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
            if let shutOffAbortInfo = shutOffTimeInfo.value(forKey: "shutOffAbortInfo") as? NSDictionary{
                if let title = shutOffAbortInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = shutOffAbortInfo.value(forKey: "subTitle") as? String{
                    lblSubTitle.stringValue = subTitle
                }
                if let shareFeedbackText = shutOffAbortInfo.value(forKey: "shareFeedbackText") as? String{
                    lbl2.stringValue = shareFeedbackText
                }
                //if let buttonCancelText = shutOffAbortInfo.value(forKey: "buttonCancelText") as? String{
                btnUnlock.title = buttonCancelText
              //  }
            }

        }
        imgViewGif.image = nil
        step = 1
        startTimer(duration: 30)
    }
    
    
    @IBAction func btnUnlockClicked(_ sender: Any) {
        if step == 1{
            //cancel aborting shutoff procewss
            currentState = ._NOTHING_//next line mai vps shutoff state setho jaygi// yha nothing isiliye set kiya qki next kine vale functon mai condition true hokar return ho rha tha ab ni hoga 
            mainViewControllerObj?.shutOffMac()
            timer?.invalidate()
        }else if step == 2{
            titleCenter.constant = 0
            getAbortJsonToUpload(emailAddress: "", feedback: textView.string, abortReason: "Shutdown skipped", completionHandler: {dic in
                DispatchQueue.main.async {
                    
                }
            })
            var startTimeHour = "\(startTime?.hour ?? 0)"
            if startTimeHour.count == 1{
                startTimeHour = "0\(startTimeHour)"
            }
            
            var startTimeMinute = "\(startTime?.minute ?? 0)"
            if startTimeMinute.count == 1{
                startTimeMinute = "0\(startTimeMinute)"
            }
            lblSubTitle.stringValue = "Sorry to hear that something bad has happened and you absolutely need to use your computer late at night. We’re unlocking your machine now. Your morning routine will still activate at \(startTimeHour):\(startTimeMinute). Hope you’re able to catch up on sleep during the day.\n\n\nUnlocking in" 
            
            
            if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
                if let shutOffAbortDoneInfo = shutOffTimeInfo.value(forKey: "shutOffAbortDoneInfo") as? NSDictionary{
                    if var subTitle = shutOffAbortDoneInfo.value(forKey: "subTitle") as? String, let unlockingText = shutOffAbortDoneInfo.value(forKey: "unlockingText") as? String{

                        subTitle = subTitle.replacingOccurrences(of: "<STARTTIME>", with: "\(startTime?.hour ?? 0):\(startTime?.minute ?? 0)")
                        lblSubTitle.stringValue = subTitle + "\n\n\n" + unlockingText
                    }
                }

            }
            
            lbl2.stringValue = ""
            startTimer(duration: 5)
            self.btnUnlock.isHidden = true
            scrollView.isHidden = true
        }
    }
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    func startTimer(duration:Int) {
        lbltimer.isHidden = false
        currentTimer = 0
        totalDuration = duration
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lbltimer.stringValue = "\(minute):\(second)"
        DispatchQueue.global().async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        //        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        //        if hour.count == 1{
        //            hour = "0\(h)"
        //        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lbltimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            if step == 1{
                self.step = 2
                self.timer?.invalidate()
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.btnUnlock.title = "Unlock"
                        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
                            if let shutOffAbortInfo = shutOffTimeInfo.value(forKey: "shutOffAbortInfo") as? NSDictionary{
                                if let buttonUnlockText = shutOffAbortInfo.value(forKey: "buttonUnlockText") as? String{
                                    self.btnUnlock.title = buttonUnlockText
                                }
                            }

                        }
                        self.lbltimer.isHidden = true
                    }
                }
            }else{
                self.timer?.invalidate()
                self.step = 3
                DispatchQueue.main.async {
                    mainViewControllerObj?.emergencyStartDone()
                }
            }
        }
    }
}
