//
//  focusEndWarningVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 11/03/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class focusEndWarningVc: NSViewController {
    
    
    @IBOutlet weak var btnExtend: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var popUpBtn: NSPopUpButton!
    @IBOutlet weak var lblSelectMinutes: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "Focus mode ends in"
        lblQuestion.stringValue = "Still in the flow? Extend the session"
        lblSelectMinutes.stringValue = "Select minutes to extend:"
        btnExtend.title = "Extend"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblTitle.stringValue = common.value(forKey: "focusEndsText") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = common.value(forKey: "askExtendFocusText") as? String ?? lblQuestion.stringValue
            lblSelectMinutes.stringValue = common.value(forKey: "extendFocusMinutesText") as? String ?? lblSelectMinutes.stringValue
            btnExtend.title = common.value(forKey: "buttonExtendText") as? String ?? btnExtend.title
            
        }
        
        
        
        
        btnCancel.title = buttonCancelText
        popUpBtn.removeAllItems()
        popUpBtn.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "90"])
    }
    override func viewWillAppear() {
        startTimer(durationSeconds: 120)
    }
    override func viewWillDisappear() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
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
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
            }
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        setProgres()
    }
    @IBAction func btnExtendClicked(_ sender: Any) {
        appdelegate?.extendFocusModeFor(minutes: Int(popUpBtn.title) ?? 0)
        self.view.window?.close()
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
}
