//
//  routineTimeVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 29/03/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class customRoutineTimeVc: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var btnSkip: Button!
    @IBOutlet weak var btnStartRoutine: Button!
    @IBOutlet weak var popUpBtnSelect: NSPopUpButton!
    @IBOutlet weak var lblSelectMinutsToPostpone: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var btnPostpone: Button!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var defaultSelectedIndex = 4
    var currentRoutineIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        popUpBtnSelect.removeAllItems()
        popUpBtnSelect.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "60", "90"])
        
        
        lblTitle.stringValue = "Your routine starts in"
        lblSelectMinutsToPostpone.stringValue = "Select minutes to postpone:"
        btnStartRoutine.title = "Start lunch break now"
        btnSkip.title = "SKIP"
        btnPostpone.title = "POSTPONE"
        lblDescription.stringValue = "You’ve got this! Follow your custom routine and check off each step as you go."
        
        if let customRoutineTimeVcInfo = configjson.value(forKey: "customRoutineTimeVcInfo") as? NSDictionary{
            lblSelectMinutsToPostpone.stringValue = customRoutineTimeVcInfo.value(forKey: "selectMinutesText") as? String ?? lblSelectMinutsToPostpone.stringValue
            btnSkip.title = customRoutineTimeVcInfo.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
            btnPostpone.title = customRoutineTimeVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
            lblDescription.stringValue = customRoutineTimeVcInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
        }
    }
    
    func resetView(index:Int){
        currentRoutineIndex = index
        startTimer(durationSeconds: 30)
        setProgres()
        
        let routine = arrAllCustomRoutine[index].title
        
        
        var titleText = "Your <ROUTINE> starts in"
        var buttonStartRoutineText = "Start <ROUTINE> now"
        
        if let customRoutineTimeVcInfo = configjson.value(forKey: "customRoutineTimeVcInfo") as? NSDictionary{
            titleText = customRoutineTimeVcInfo.value(forKey: "title") as? String ?? titleText
            buttonStartRoutineText = customRoutineTimeVcInfo.value(forKey: "buttonStartRoutineText") as? String ?? buttonStartRoutineText
        }
        
        titleText = titleText.replacingOccurrences(of: "<ROUTINE>", with: routine)
        buttonStartRoutineText = buttonStartRoutineText.replacingOccurrences(of: "<ROUTINE>", with: routine)
        lblTitle.stringValue = titleText
        btnStartRoutine.title = buttonStartRoutineText
        
        popUpBtnSelect.selectItem(at: defaultSelectedIndex)
    }
    
    
    func startTimer(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.progressBar.maxValue = 30
        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
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
            self.progressBar.doubleValue = Double(remainingSeconds)
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                if currentState == ._CUSTOM_ROUTINE_{// whenever show waring then make current state _CUSTOM_ROUTINE_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute _CUSTOM_ROUTINE_)
//                    mainViewControllerObj?.showRoutineAllHabits(routineIndex: self.currentRoutineIndex)
                    startCustomRoutine(index: self.currentRoutineIndex, isOnDemand:false)
                }
            }
        }
    }
    
    @objc func performTimerCount() {
        currentTimer += 1
        setProgres()
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "[user-action] customRoutineTimeVc:- btn Postpone Clicked")
        allApiObject.capturePosthog(event: "postpone-custom-routine-from-warning", metadata: [:])
        self.timer?.invalidate()
        self.view.window?.close()
        if currentState == ._CUSTOM_ROUTINE_{
            if !arrAllCustomRoutine[currentRoutineIndex].triggerOnDemand{
                mainViewControllerObj?.postponeCustomRoutineFor(minutes: Int(popUpBtnSelect.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                return;
            }
        }
        currentState = ._NOTHING_
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] customRoutineTimeVc - Skip Clicked")
        allApiObject.capturePosthog(event: "skip-custom-routine-warning", metadata: [:])
        self.timer?.invalidate()
        self.view.window?.close()
        currentState = ._NOTHING_
        arrAllCustomRoutine[currentRoutineIndex].skipForDate = Date()
    }
    
    @IBAction func btnStartRoutineClicked(_ sender: Any) {
        addLog(text: "[user-action] customRoutineTimeVc - btnStartRoutineClicked")
        self.timer?.invalidate()
        self.view.window?.close()
        if currentState == ._CUSTOM_ROUTINE_{
            allApiObject.capturePosthog(event: "custom-routine-started-early", metadata: [:])
            startCustomRoutine(index: self.currentRoutineIndex, isOnDemand:false)
        }else{
            currentState = ._NOTHING_
        }
        
    }
    
    @IBAction func popUpBtnSelectClicked(_ sender: Any) {
        
    }
}
