//
//  discourageDefaultFocusVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 11/04/22.
//  Copyright © 2022 . All rights reserved.
//

import Cocoa

class discourageDefaultFocusVc: NSViewController {// not in use

    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblShutUp: NSTextField!
    @IBOutlet weak var lblCancel: NSTextField!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnShutUp: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var currentTimer = 0
    var totalDuration = 5
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnShutUp.buttonColor = NSColor.white.cgColor
        lblCancel.stringValue = "Bah I guess you're right - CANCEL!"
        lblShutUp.stringValue = "Shutup I know what I'm doing"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let discourageDefaultFocusInfo = focusInfo.value(forKey: "discourageDefaultFocusInfo") as? NSDictionary{
                if let buttonCancelText = discourageDefaultFocusInfo.value(forKey: "buttonCancelText") as? String{
                    lblCancel.stringValue = buttonCancelText
                }
                if let buttonShutUpText = discourageDefaultFocusInfo.value(forKey: "buttonShutUpText") as? String{
                    lblShutUp.stringValue = buttonShutUpText
                }
            }
        }
    }
    override func viewWillAppear() {
        print("viewWillAppear")
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        
        //isDiscourageDefaultFocusVcVisible = true
    }
    override func viewWillDisappear() {
        print("viewWillDisappear")
        //isDiscourageDefaultFocusVcVisible = false
    }
    func resetData(){
        lblTimer.isHidden = true
        btnCancel.isHidden = false
        btnShutUp.isHidden = false
        lblShutUp.isHidden = false
        lblCancel.isHidden = false
        lblTitle.stringValue = "Are you sure? It's pretty easy to get distracted without using a more restrictive focus mode"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let discourageDefaultFocusInfo = focusInfo.value(forKey: "discourageDefaultFocusInfo") as? NSDictionary{
                if let title = discourageDefaultFocusInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
            }
        }
        
    }
    
    
    @IBAction func btnShutupClicked(_ sender: Any) {
        addLog(text: "[user-action] discourageDefaultFocusVc - btnEditFocusModeClicked")//
        lblTimer.isHidden = false
        btnCancel.isHidden = true
        btnShutUp.isHidden = true
        lblShutUp.isHidden = true
        lblCancel.isHidden = true
        lblTitle.stringValue = "Ok good luck! (You'll need it 😅)"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let discourageDefaultFocusInfo = focusInfo.value(forKey: "discourageDefaultFocusInfo") as? NSDictionary{
                if let titleGoodLuck = discourageDefaultFocusInfo.value(forKey: "titleGoodLuck") as? String{
                    lblTitle.stringValue = titleGoodLuck
                }
            }
        }
        
        startTimer()
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "[user-action] discourageDefaultFocusVc - btnCancelClicked")//
       // if focusModeStartWindowLodded{
//            if startingFocusWindowControllerObj?.window?.isVisible ?? false{
//                if self.view.window?.sheetParent?.windowController == startingFocusWindowControllerObj{
//                    self.dismiss(self)
//                    startingFocusWindowControllerObj?.window?.close()
//                    return
//                }
//            }
       // }
        self.dismiss(self)
    }
    
    func startTimer() {
        currentTimer = 0
        totalDuration = 5
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
            self.lblTimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.dismiss(self)
                    if pomodoroWindowControllerObj != nil{
                        if pomodoroWindowControllerObj?.window?.isVisible ?? false{//it means pomodoro start hoga
                            if pomodoroVcObj!.btnCheckBoxHardcodePomodoro.state == .on{
                                isHardCorePomodoroModeOn = true
                                hardcodePmodoroFocusModeName = pomodoroVcObj!.popUpBtnFocusType.titleOfSelectedItem ?? ""
                                let totalPopmodoroCount = Int(pomodoroVcObj!.popupBtnSelectPomodoroCount.title) ?? 2
                                let minutes = currentPomodoroWorkDuration
                                totalPomodoroCountInHardCorePomodoro = totalPopmodoroCount
                                completedPomodoroCountInHardcorePomodoro = 0
                                let totoalMinutes = (totalPopmodoroCount * minutes)// * 60//(textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
                                totalMinutesRemainingForHardcodePomodoro = totoalMinutes
                            }
                            
                            pomodoroVcObj!.pomodoroModeStarted()
                            pomodoroVcObj!.view.window?.close()
                        }else{
                            
                        }
                    }else{
                        
                    }
                    
                }
            }
        }
    }
    
}
