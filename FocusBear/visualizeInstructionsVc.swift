//
//  visualizeInstructions.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class visualizeInstructionsVc: NSViewController {

    @IBOutlet weak var btnSkipHabit: underLineButton!
    @IBOutlet weak var btnMain: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblVisualizeText: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Get Focused"
        lblVisualizeText.stringValue = "Before you begin your morning routine, take 30 seconds to engage in \"extrapersonal focus\": try your best to keep your eyes fixed on the target. Research from Balcetis and colleagues in 2020 indicates that concentrating on a visual point will sharpen your focus and increase the likelihood of completing your routine."
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            lblVisualizeText.stringValue = activityInfo.value(forKey: "visualizeDescriptionText") as? String ?? lblVisualizeText.stringValue
            lblTitle.stringValue = activityInfo.value(forKey: "titleGetFocused") as? String ?? lblTitle.stringValue
        }
        btnSkipHabit.title = "Skip this habit for today"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        
    }
    override func viewWillAppear() {
        if currentState == ._MORNING_HABIT_{
            if arrAllMorningHabits.count != 0 {
                let time = arrAllMorningHabits[0].durationSeconds!
                btnMain.title = getstartActivityButtonText(seconds: time, name: arrAllMorningHabits[0].name!)
            }
        }else if currentState == ._EVENING_HABIT_{
            if arrAllEveningHabits.count != 0 {
                let time = arrAllEveningHabits[0].durationSeconds!
                btnMain.title = getstartActivityButtonText(seconds: time, name: arrAllEveningHabits[0].name!)
            }
        }
    }
    func startTimer(){
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.stringValue = ""
        startTimer(duration: 30)
    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0
    
    func startTimer(duration:Int) {
        if isTimerGoingOn{
            btnMain.isHidden = true
            lblTimer.isHidden = false
            btnSkipHabit.isHidden = true
            return
        }
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.isHidden = false
        isTimerGoingOn = true
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
        currentTimer += 1 // todo 1 kro
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
                playEveryActivitySound()
                self.btnMain.isHidden = false
                self.btnSkipHabit.isHidden = false
                self.lblTimer.isHidden = true
                self.isTimerGoingOn = false
                
                if currentState == ._MORNING_HABIT_{
                    if arrAllMorningHabits.count != 0 {
                        let time = arrAllMorningHabits[0].durationSeconds!
                        self.btnMain.title = getstartActivityButtonText(seconds: time, name: arrAllMorningHabits[0].name!)

                    }
                }else if currentState == ._EVENING_HABIT_{
                    if arrAllEveningHabits.count != 0 {
                        let time = arrAllEveningHabits[0].durationSeconds!
                        self.btnMain.title = getstartActivityButtonText(seconds: time, name: arrAllEveningHabits[0].name!)

                    }
                }
            }
        }
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        if currentState == ._MORNING_HABIT_{
            mainViewControllerObj?.startFirstMorningHabit()
        }else{
            mainViewControllerObj?.startFirstEveningHabit()
        }
    }
    @IBAction func btnSkipClicked(_ sender: Any) {
        thirdVcObj?.loadView()
        thirdVcObj?.btnSkipHabitClicked(self)
    }
}
