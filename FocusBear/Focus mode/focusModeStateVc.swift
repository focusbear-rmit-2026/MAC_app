//
//  focusModeStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class focusModeStateVc: NSViewController {
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStopFocusMode: Button!
    @IBOutlet weak var lblTitleFocusModeTime: NSTextField!
    @IBOutlet weak var lblTimerFocusMode: NSTextField!
    @IBOutlet weak var boxFocusModeRemainingTime: NSBox!
    
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleFocusModeTime.stringValue = "Focus mode ends in:"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let focusEndsText = common.value(forKey: "focusEndsText") as? String {
                lblTitleFocusModeTime.stringValue = focusEndsText + ":"
            }
        }
    }
    
    override func viewWillAppear() {
        reloadData()
        isViewVisible = true
    }
    
    
    
    func reloadData(){
        let isFocusModeOn = isFocusModeOn()
        let isFocusModePaused = isFocusModePaused()
        stopFocusModeCountDownTimer()
        if isFocusModeOn{
            showFocusModeCountDownIfNeeded()
            btnStopFocusMode.title = "Stop Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnStopFocusMode.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? btnStopFocusMode.title
            }
        }else if isFocusModePaused{
            lblTitle.isHidden = false
            btnStopFocusMode.title = "Resume Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnStopFocusMode.title = leftMenuVcInfo.value(forKey: "menuResumeFocusSession") as? String ?? btnStopFocusMode.title
            }
            
            lblTitle.stringValue = "Focus Session is paused."
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                if let focusSessionPausedText = common.value(forKey: "focusSessionPausedText") as? String {
                    lblTitle.stringValue = focusSessionPausedText
                }
            }
            boxFocusModeRemainingTime.isHidden = true
        }else if isHardCorePomodoroModeOn{
            lblTitle.isHidden = true
            boxFocusModeRemainingTime.isHidden = true
            btnStopFocusMode.title = "Stop Super Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnStopFocusMode.title = leftMenuVcInfo.value(forKey: "menuStopSuperFocusSession") as? String ?? btnStopFocusMode.title
            }
        }
    }
    
    override func viewWillDisappear() {
        stopFocusModeCountDownTimer()
        isViewVisible = false
    }
    
    var timerFocusModeCoundDown:Timer?
    func setFocusModeCoundDownTimer(){
        lblTitle.isHidden = true
        stopFocusModeCountDownTimer()
        boxFocusModeRemainingTime.isHidden = false
        DispatchQueue.global().sync {
            self.timerFocusModeCoundDown = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performFocusModeCoundDown), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerFocusModeCoundDown!), forMode: RunLoop.Mode.common)
        }
        performFocusModeCoundDown()
    }
    
    
    func showFocusModeCountDownIfNeeded(){
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning) && endFocusModeTime != nil{
            setFocusModeCoundDownTimer()
        }else{
            stopFocusModeCountDownTimer()
        }
    }
    
    
    @objc func performFocusModeCoundDown(){
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning){
            if let date = endFocusModeTime{
                let secondsBetween = date.timeIntervalSince(Date())
                if secondsBetween < 0{
                    stopFocusModeCountDownTimer()
                }
                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
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
                

                let finalTitle = "\(hour):\(minute):\(second)"
                lblTimerFocusMode.stringValue = finalTitle
            }else{
                stopFocusModeCountDownTimer()
            }
        }else{
            stopFocusModeCountDownTimer()
        }
    }
    
    
    func stopFocusModeCountDownTimer(){
        self.timerFocusModeCoundDown?.invalidate()
        self.timerFocusModeCoundDown = nil
        boxFocusModeRemainingTime.isHidden = true
    }
    
    @IBAction func btnStopFocusModeClicked(_ sender: Any) {
//        if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
//            addLog(text: "focus mode clicked:- focus mode completed Window is visible:- return")
//            return;
//        }

        var isFocusModeOn = false
        
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isOn"] as? Bool == true || arrFocusType[index]["isPaused"] as? Bool == true{
                //abort focus mode
                // new work 13/3/22
                isFocusModeOn = true
                if arrFocusType[index]["isOn"] as? Bool == true{
//                    if currentFocusModeStrictness == ._SUPER_STRICT_{
//                        addLog(text: "can't stop focus mode in super strict focus mode :- return")
//                        var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
//                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                            cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
//                        }
//                        showTooltip(sender: btnStopFocusMode, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
//                        return;
//                    }
                    
                    let menu = NSMenu()
                    if timerForFocusMode != nil{
                        let menuItemPause = NSMenuItem(title: "Pause Focus Session", action: #selector(pauseFocusMode), keyEquivalent: "")
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            menuItemPause.title = menuInfo.value(forKey: "menuItemPauseFocusTitle") as? String ?? menuItemPause.title
                        }
                        menuItemPause.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                        menuItemPause.target = self
                        menu.addItem(menuItemPause)
                    }
                    
                    let menuItemStop = NSMenuItem(title: "Stop Focus Session", action: #selector(stopFocusMode), keyEquivalent: "")
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        menuItemStop.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? menuItemStop.title
                    }
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    menu.minimumWidth = btnStopFocusMode.frame.width
                    let p = NSPoint(x: btnStopFocusMode.frame.origin.x, y: btnStopFocusMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStopFocusMode)
                    
                    break;
                }else if arrFocusType[index]["isPaused"] as? Bool == true{
                    
                    let menu = NSMenu()
                    let menuItemResume = NSMenuItem(title: "Resume Focus Session", action: #selector(resumeFocusMode), keyEquivalent: "")
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        menuItemResume.title = leftMenuVcInfo.value(forKey: "menuResumeFocusSession") as? String ?? menuItemResume.title
                    }
                    menuItemResume.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                    menuItemResume.target = self
                    menu.addItem(menuItemResume)
                    
                    let menuItemStop = NSMenuItem(title: "Stop Focus Session", action: #selector(stopFocusMode), keyEquivalent: "")
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        menuItemStop.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? menuItemStop.title
                    }
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    
                    
                    menu.minimumWidth = btnStopFocusMode.frame.width
                    let p = NSPoint(x: btnStopFocusMode.frame.origin.x, y: btnStopFocusMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStopFocusMode)
                    break;
                }
            }
        }
        
        
        
        if !isFocusModeOn{
            if isHardCorePomodoroModeOn{
                if shouldAskPassword(){
                    if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                        menuViewControllerObj?.showPasswordWindow()
                        addLog(text: "Showing enter password view from hardcodre pomodoro stop from menu")
                    }else{
                        isHardCorePomodoroModeOn = false
                        reloadData()
                        leftMenuVcObj?.boxFocusSession.isSelected = true
                        if SettingsManagerObject.isGeekModeEnabled{
                            appdelegate?.menuShowPomodoroModeView()
                        }else{
                            appdelegate?.menuShowSimplePomodoroModeView()
                        }
                    }
                }else{
                    isHardCorePomodoroModeOn = false
                    reloadData()
                    if SettingsManagerObject.isGeekModeEnabled{
                        appdelegate?.menuShowPomodoroModeView()
                    }else{
                        appdelegate?.menuShowSimplePomodoroModeView()
                    }
                }
            }else{
               
            }
        }else{
            
        }
    }
    
    @objc func pauseFocusMode(){
        menuViewControllerObj?.pauseFocusModeClicked()
    }
    
    @objc func stopFocusMode(){
        menuViewControllerObj?.stopFocusMode()
    }
    
    @objc func resumeFocusMode(){
        menuViewControllerObj?.resumeFocusMode()
    }
}
