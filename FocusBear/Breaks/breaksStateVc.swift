//
//  breaksStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 12/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class breaksStateVc: NSViewController {

 
    @IBOutlet weak var lblNextBreakTime: NSTextField!
    @IBOutlet weak var btnEnableMicroBreaks: Button!
    @IBOutlet weak var lblEnableBreaks: NSTextField!
    @IBOutlet weak var btnStartMicroBreaks: Button!
    
    var isViewVisible = false
    var timerReload:Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnEnableMicroBreaks.title = "Enable Breaks"
        btnStartMicroBreaks.title = "Start Break"
        
        if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
            btnEnableMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonEnableBreaks") as? String ?? btnEnableMicroBreaks.title
            btnStartMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonStartBreak") as? String ?? btnStartMicroBreaks.title
        }
    }
    
    override func viewWillAppear() {
        isViewVisible = true
        reloadData()
        
        self.timerReload?.invalidate()
        self.timerReload = nil
        DispatchQueue.global().sync {
            self.timerReload = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.reloadIfNeeded), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerReload!), forMode: RunLoop.Mode.common)
        }
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
        self.timerReload?.invalidate()
        self.timerReload = nil
    }
    
    @objc func reloadIfNeeded(){
        if isViewVisible{
            reloadData()
        }else{
            self.timerReload?.invalidate()
            self.timerReload = nil
        }
    }
   
    func reloadData() {
        addLog(text:"breaksStateVc:- reloadData")
        if !isAppEnable{
            btnEnableMicroBreaks.title = "Activate Distraction Blocking"
            lblEnableBreaks.stringValue = "Distraction Blocking is currently paused. You can turn it back on anytime to stay focused."

            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                btnEnableMicroBreaks.title = menuInfo.value(forKey: "menuItemReactivateTitle") as? String ?? btnEnableMicroBreaks.title
            }
            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                lblEnableBreaks.stringValue = habitsStateVcInfo.value(forKey: "titleAppDisabled") as? String ?? lblEnableBreaks.stringValue
            }
            
            lblEnableBreaks.isHidden = false
            btnEnableMicroBreaks.isHidden = false
            lblNextBreakTime.isHidden = true
            btnStartMicroBreaks.isHidden = true
            return;
        }
        
        btnEnableMicroBreaks.title = "Enable Breaks"
        btnStartMicroBreaks.title = "Start Break"
        
        if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
            btnEnableMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonEnableBreaks") as? String ?? btnEnableMicroBreaks.title
            btnStartMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonStartBreak") as? String ?? btnStartMicroBreaks.title
        }
        var isBreakEnabled = SettingsManagerObject.isMicroBreaksEnabled
        
        if !isBreakEnabled{
            lblEnableBreaks.stringValue = "Breaks are currently disabled. Enable taking breaks at regular intervals to boost your productivity, energy levels, and focus."
            
            if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                lblEnableBreaks.stringValue = breakStateVcInfo.value(forKey: "titleEnableBreaks") as? String ?? lblEnableBreaks.stringValue
            }
            lblEnableBreaks.isHidden = false
            btnEnableMicroBreaks.isHidden = false
            lblNextBreakTime.isHidden = true
            btnStartMicroBreaks.isHidden = true
            return;
        }
        if let disableBreaksForTodayDate = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date{
            if Calendar.current.isDateInToday(disableBreaksForTodayDate){
                isBreakEnabled = false
                lblEnableBreaks.stringValue = "You’ve paused breaks for today. They’ll be back tomorrow to help you recharge and focus."
                if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                    lblEnableBreaks.stringValue = breakStateVcInfo.value(forKey: "pausedBreaksText") as? String ?? lblEnableBreaks.stringValue
                }
                lblEnableBreaks.isHidden = false
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = true
                btnStartMicroBreaks.isHidden = true
                return;
            }
        }
        
        if getHabitsVcObject().breakTimer != nil && isBreakEnabled{
            if getHabitsVcObject().breakTimer!.isValid{
              //  boxNextBreak.isHidden = false
                let currentTime = Date()
                let breakTime = getHabitsVcObject().breakTimer!.fireDate
                let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                var timeText = "\(diffMinute) \(minutesText)"
                if diffMinute < 1{
                    timeText = "< 1 \(minuteText)"
                }
                var nextBreakText = "Next break in: <DURATION>"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    nextBreakText = menuInfo.value(forKey: "nextBreakText") as? String ?? nextBreakText
                }
                nextBreakText = nextBreakText.replacingOccurrences(of: "<DURATION>", with: timeText)
                lblNextBreakTime.stringValue = nextBreakText
                
                lblEnableBreaks.isHidden = true
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = false
                btnStartMicroBreaks.isHidden = false
                if diffMinute < 1{//show the break as soon as there are 5 seconds of inactivity
                    let diffSeconds = Calendar.current.dateComponents([.second], from: currentTime, to: breakTime).second ?? 0
                    if diffSeconds < 5{
                        lblNextBreakTime.stringValue = "It's time for a break. Waiting for a good moment"
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                        }
                    }
                }
            }
        }else{
            if isShutOffTimeGoing(){
                lblEnableBreaks.isHidden = false
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = true
                btnStartMicroBreaks.isHidden = true
                lblEnableBreaks.stringValue = "App is in shutoff state"
                if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                    lblEnableBreaks.stringValue = breakStateVcInfo.value(forKey: "shutoffTimeText") as? String ?? lblEnableBreaks.stringValue
                }
            }else if currentState == ._MICRO_BREAK_{ // if by any chance user is on this view (for example break warning is visible beacuse during warning state is micro break)
                lblNextBreakTime.stringValue = "It's time for a break. Waiting for a good moment"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                }
                
                
                lblEnableBreaks.isHidden = true
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = false
                btnStartMicroBreaks.isHidden = false
            }else if getHabitsVcObject().breakTimer == nil{
                lblNextBreakTime.stringValue = "No upcoming break has been scheduled yet."// todo text 
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                    lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                }
                lblEnableBreaks.isHidden = true
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = false
                btnStartMicroBreaks.isHidden = false
            }
        }
    }
    
    @IBAction func btnEnableMicroBreaksClicked(_ sender: Any) {
        if !isAppEnable{
            addLog(text:"[user-action] breaksStateVc:- button Reactivate clicked")
            appdelegate?.menuItem_Reactivate()
            return;
        }
        addLog(text:"[user-action] breaksStateVc:- button Enable breaks clicked")
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isMicroBreaksEnabled = true
        allApiObject.capturePosthog(event: "settings-changed-enable-breaks", metadata: [:])
        SettingsManagerObject.putUserLocalDeviceSettings()
        reloadData()
    }
    
    @IBAction func btnStartMicroBreaksClicked(_ sender: Any) {
        addLog(text:"[user-action] breaksStateVc:- button Start Micro breaks clicked")
        menuViewControllerObj?.btnStartBreakClicked(self)
    }
    
}
