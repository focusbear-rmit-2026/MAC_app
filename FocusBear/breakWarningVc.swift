//
//  breakWarningVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class breakWarningVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var isPostponing = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    func resetView(){
        progressBar.isHidden = false
        isPostponing = false
        lblTitle.stringValue = "Your Break starts in"
        btnPostpone.title = "Postpone for 5 minutes"
        startTimer(durationSeconds: 30)
        setProgres()
        
        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
            lblTitle.stringValue = breakWarningVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
        }
        
    }
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
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
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
            if !self.isPostponing{
                self.progressBar.doubleValue = Double(remainingSeconds)
            }
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                
                if self.isPostponing{
                    mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5)
                }else{
                    if !isShutOffTimeGoing(){
                        mainViewControllerObj?.executeBreakActivities()
                    }
                }
            }
        }
    }
    @objc func performTimerCount() {

        currentTimer += 1//todo 1 kro 
        setProgres()
        
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "breakWarningVc:- btnPostponeClicked")
        if isPostponing{
            addLog(text: "breakWarningVc:- btn take break clicked")
            self.timer?.invalidate()
            self.view.window?.close()
            if !isShutOffTimeGoing(){
                mainViewControllerObj?.executeBreakActivities()
            }
            
        }else{
            addLog(text: "breakWarningVc:- btn Postpone clicked")
            if activityPostponeCount != 0{
                addLog(text: "breakWarningVc:- btn Postpone timer begin")
                isPostponing = true
                self.timer?.invalidate()
                lblTitle.stringValue = "You postponed the last break - are you sure you can't make time for The break now?"
                btnPostpone.title = "Argh ok I'll take a break!"
                progressBar.isHidden = true
                startTimer(durationSeconds: 15)
                if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
                    lblTitle.stringValue = breakWarningVcInfo.value(forKey: "postponeConfirmText") as? String ?? lblTitle.stringValue
                    btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnPostpone.title
                }
            }else{
                self.timer?.invalidate()
                self.view.window?.close()
                mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5)
                activityPostponeCount += 1
            }
        }
    }
}

