//
//  smallCountDownVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class smallCountDownVc: NSViewController {

    @IBOutlet weak var lblTimerTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnPostpone: underLineButton!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var isFocusBreak = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnPostpone.title = "Postpone"//todo text
    }
    func closeTimerBox(){
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
    }
    override func viewWillAppear() {
        btnPostpone.isHidden = true
        //****** Allow  postpone from timer window in morning evening routine in allow app case******//#213  date- 5/9/22
//        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
//            lblTimerTopSpaceConstraint.constant = 10
//            btnPostpone.isHidden = false
//        }else{
//            lblTimerTopSpaceConstraint.constant = 15
//            btnPostpone.isHidden = true
//        }
    }
    @IBAction func btnPostponeClicked(_ sender: Any) {
        mainWindowControllerObj?.window?.setIsVisible(true)
        showBlankWindowInSecondaryMonitor()
        mainViewControllerObj?.btnAbortClicked(self)
    }
    func startTimerHabit(durationSeconds:Int, msg:String) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        if !isFocusBreak{
            lblTitle.stringValue = msg//getDoSomeActivityText(activityName: name)
        }else{
            lblTitle.stringValue = "Your break ends in"//Your break ends in timer
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                lblTitle.stringValue = common.value(forKey: "focusBreakNotificationTitle") as? String ?? lblTitle.stringValue
            }
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
    
    @objc func performTimerCount() {
            
            currentTimer += 1 // todo 1 kro 
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
            
            DispatchQueue.main.async {
                if h == 0{
                    self.lblTimer.stringValue = "\(minute):\(second)"
                }else{
                    self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
                }
            }
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                if isFocusBreak{
                    playFocusPomodorBreakEndsSound()
                }
            }
        }
}
