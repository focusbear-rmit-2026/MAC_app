//
//  skipHabitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 09/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class skipHabitVc: NSViewController {

    @IBOutlet weak var btnDoHabit: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Skipping habit in"
        btnDoHabit.title = "I changed my mind - I'll do my habits"
        
        if let skipHabitVcInfo = configjson.value(forKey: "skipHabitVcInfo") as? NSDictionary{
            lblTitle.stringValue = skipHabitVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnDoHabit.title = skipHabitVcInfo.value(forKey: "buttonDoHabitsText") as? String ?? btnDoHabit.title
        }
        
    }
    func resetView(){
        addLog(text: "skipHabitVc - resetView")
        
        if SettingsManagerObject.isEasySkipEnabled{
            skipHabit()
        }else{
            startTimer(duration: 15)
        }
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        timer?.invalidate()
        timer = nil
        self.view.removeFromSuperview()
        
//        if currentHabitPlaying != nil{//it means allowed app activity
//            mainWindowControllerObj?.window?.close()
//            hideBlankWindowInSecondaryMonitor()
//            currentState = ._NOTHING_
//            appdelegate?.backgroundThread()
//        }
    }
    @IBAction func btnDoHabitClicked(_ sender: Any) {
        timer?.invalidate()
        timer = nil
        self.view.removeFromSuperview()
    }
    func startTimer(duration:Int) {
        lblTimer.isHidden = false
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
        self.lblTimer.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
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
            self.lblTimer.isHidden = false
            self.lblTimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            
            self.timer?.invalidate()
            DispatchQueue.main.async {
                self.skipHabit()
            }
        }
    }
    
    func skipHabit(){
        self.lblTimer.isHidden = true
        self.view.removeFromSuperview()
        
        if rememberNextHabitVcObj != nil{
            if thirdVcObj!.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj!.view.removeFromSuperview()
                thirdVcObj?.boxBg.isHidden = false
            }
        }
        if currentAction == ._VISUALIZE_{
            getHabitsVcObject().showThirdVc()
        }
        if currentAction == ._INPROGRESS_{
            getHabitsVcObject().showThirdVc()
        }
        if currentAction == ._START_{// break activity case
            getHabitsVcObject().showThirdVc()
        }
        
        if currentState == ._MICRO_BREAK_{
            thirdVcObj?.activitySkipped()
        }else if currentState == ._MORNING_HABIT_{
            thirdVcObj?.morningHabitSkipped()
        }else if currentState == ._EVENING_HABIT_{
            thirdVcObj?.eveningHabitSkipped()
        }else if currentState == ._CUSTOM_ROUTINE_{
            thirdVcObj?.customRoutineHabitSkipped()
        }
    }
}
