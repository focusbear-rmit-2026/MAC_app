//
//  smallCountDownVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class smallCountDownVc: NSViewController {

    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var isFocusBreak = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
            
            currentTimer += 1
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
            }
        }
}
