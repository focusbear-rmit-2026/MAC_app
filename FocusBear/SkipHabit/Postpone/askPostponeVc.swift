//
//  askPostponeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askPostponeVc: NSViewController {

    @IBOutlet weak var btnCancelPostpone: cursorButton!
    @IBOutlet weak var lblSelectMinutes: NSTextField!
    @IBOutlet weak var btnOkIWillDoBreak: Button!
    @IBOutlet weak var btnAbortBreak: Button!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var popUpButtonSelectMinutes: NSPopUpButton!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        
        lblSelectMinutes.stringValue = "Select minutes to postpone:"
        popUpButtonSelectMinutes.removeAllItems()
        popUpButtonSelectMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "60", "90"])
        
        btnOkIWillDoBreak.title = "Argh ok I'll take a break!"
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnOkIWillDoBreak.title
            lblSelectMinutes.stringValue = activityPostponeInfo.value(forKey: "selectMinutesText") as? String ?? lblSelectMinutes.stringValue
        }
        
    }
    
    override func viewWillAppear() {
        
    }
    @IBAction func btnCancelPostponeClicked(_ sender: Any) {
        if currentState == ._MICRO_BREAK_{
            self.timer?.invalidate()
            self.timer = nil
            lblTimer.isHidden = true
            self.view.removeFromSuperview()
            if currentAction == ._INPROGRESS_{
                getHabitsVcObject().abortCancel()
            }else if currentAction == ._START_{
                getHabitsVcObject().showCloseButtons()
            }else if currentAction == ._END_{
                getHabitsVcObject().showCloseButtons()
            }else if currentAction == ._BRAIN_DUMP_{
                getHabitsVcObject().showCloseButtons()
            }
        }else{
            self.view.removeFromSuperview()
            getHabitsVcObject().abortCancel()
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    func resetView(){
        addLog(text: "Ask postpone view - resetView")
        isShowingAskOfficeModeView = false
        btnPostpone.isHidden = false
        btnAbortBreak.isHidden = false
        btnOkIWillDoBreak.isHidden = true
        lblTimer.isHidden = true
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if activityPostponeCount == 0{
                showHabitPostponeView()
            }else{
                showHabitTimerView()
            }
            
        }else if currentState == ._FOCUS_SUMMARY_{
            
            
            popUpButtonSelectMinutes.isHidden = false
            lblSelectMinutes.isHidden = false
            popUpButtonSelectMinutes.selectItem(at: 0)
            lblTitle.stringValue = "If you have something urgent, you can postpone Habits for few Minutes."
            btnPostpone.title = "Postpone Habit"
            btnAbortBreak.title = "Completely Skip"
            
            if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponeHabitsText") as? String ?? lblTitle.stringValue
                btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeHabitText") as? String ?? btnPostpone.title
                btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonCompletelySkipText") as? String ?? btnAbortBreak.title
            }
            
            btnPostpone.buttonColor = buttonBgColor.cgColor
            btnAbortBreak.buttonColor = NSColor.white.cgColor
            
            
            
        }else if currentState == ._MICRO_BREAK_{
       
            /*
            popUpButtonSelectMinutes.isHidden = true
            lblSelectMinutes.isHidden = true
            lblTitle.stringValue = "If you have something urgent, you can postpone the Break Activity for 5 Minutes."
            btnPostpone.title = "Postpone Break"
            btnAbortBreak.title = "Switch to office mode"
            
            if SettingsManagerObject.isOfficeModeEnabled{
                btnAbortBreak.isHidden = true
                btnPostpone.buttonColor = buttonBgColor.cgColor
            }else{
                
                let filterArr = arrAllbreakActivities.filter { $0.isOfficeFriendly == true}
                if filterArr.count == 0{// no activity found with isOfficeFriendly //
                    addLog(text: "Ask postpone view - resetView :- no activity found with isOfficeFriendly")
                    btnAbortBreak.isHidden = true
                    btnPostpone.buttonColor = buttonBgColor.cgColor
                }else{
                    btnAbortBreak.isHidden = false
                    btnPostpone.buttonColor = NSColor.white.cgColor
                    btnAbortBreak.buttonColor = buttonBgColor.cgColor
                }
            }
            if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponeBreakText") as? String ?? lblTitle.stringValue
                btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnPostpone.title
                btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonEnableOfficeModeText") as? String ?? btnAbortBreak.title
            }
            */
        
            if activityPostponeCount == 0{
                if SettingsManagerObject.isOfficeModeEnabled{
                    self.showActivityostponeView()
                }else{
                    self.showAskOfficeModeView()
                }
            }else{
                showActivityTimerView()
            }
        }
    }

    func showActivityostponeView(){
        isShowingAskOfficeModeView = false
        popUpButtonSelectMinutes.isHidden = false
        lblSelectMinutes.isHidden = false
        lblTitle.stringValue = "Want to postpone the break or skip it completely?"
        btnPostpone.title = "Postpone Break"
        btnAbortBreak.title = "Skip Completely"
        btnOkIWillDoBreak.isHidden = true
        btnAbortBreak.isHidden = false
        btnPostpone.isHidden = false
       
        btnPostpone.buttonColor = buttonBgColor.cgColor
        btnAbortBreak.buttonColor = NSColor.white.cgColor
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            lblTitle.stringValue = activityPostponeInfo.value(forKey: "titlePostponeOrSkip") as? String ?? lblTitle.stringValue
            btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonSkipCompletelyText") as? String ?? btnAbortBreak.title
            btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnPostpone.title
        }
    }
    func showActivityTimerView(){
        addLog(text: "Ask postpone view - 15 Seconds timer")
        btnAbortBreak.isHidden = true
        btnPostpone.isHidden = true
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        btnOkIWillDoBreak.isHidden = false
        lblTitle.stringValue = "You postponed the last break - are you sure you can't make time for the break now?"
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponedLastBreakText") as? String ?? lblTitle.stringValue
        }
        btnOkIWillDoBreak.title = "Argh ok I'll take a break!"
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnOkIWillDoBreak.title
        }
        
        startTimer(duration: 15)
    }
    var isShowingAskOfficeModeView = false
    func showAskOfficeModeView(){
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        var currentActicityTitle = ""
        if currentAction == ._INPROGRESS_{
            currentActicityTitle = timerViewcontrollerObj?.currentActicityTitle ?? ""
        }else if currentAction == ._END_{
            currentActicityTitle = thirdVcObj?.activityName ?? ""
        }else if currentAction == ._START_{
            currentActicityTitle = thirdVcObj?.activityName ?? ""
        }
        btnPostpone.title = "I don't have time"
        btnAbortBreak.title = "I'm in the offIce"
        
        var title = "Do you not have time for a break right now or are you in the office and it's not appropriate to do <ACTIVITY>?"
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            title = activityPostponeInfo.value(forKey: "titleAskOfficeMode") as? String ?? title
            btnPostpone.title = activityPostponeInfo.value(forKey: "buttonDontHaveTimeText") as? String ?? btnPostpone.title
            btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonInTheOffIceText") as? String ?? btnAbortBreak.title
        }
        
        
        lblTitle.stringValue = title.replacingOccurrences(of: "<ACTIVITY>", with: currentActicityTitle)
       
        isShowingAskOfficeModeView = true
        btnPostpone.isHidden = false
        btnOkIWillDoBreak.isHidden = true
        
        btnAbortBreak.isHidden = false
        btnPostpone.buttonColor = NSColor.white.cgColor
        btnAbortBreak.buttonColor = buttonBgColor.cgColor

//        }
        
    }
    func showHabitTimerView(){
        lblTitle.stringValue = "You've postponed your habits a few times. Are you sure you want to postpone again?"
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        btnAbortBreak.isHidden = true
        btnPostpone.isHidden = true
        btnOkIWillDoBreak.isHidden = true
        
        var timer = 0
        switch activityPostponeCount {
        case 1:
            timer = 5
        case 2:
            timer = 10
        case 3:
            timer = 15
        case 4:
            timer = 30
        case 5:
            timer = 45
        case 6:
            timer = 60
        default:
            timer = 60
        }
        
        startTimer(duration: timer)
        btnOkIWillDoBreak.isHidden = false
        btnOkIWillDoBreak.title = "I changed my mind - I'll do my habits"
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponedLastHabitText") as? String ?? lblTitle.stringValue
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonDoHabitText") as? String ?? btnOkIWillDoBreak.title
        }
        
    }
    
    func showHabitPostponeView(){
        popUpButtonSelectMinutes.isHidden = false
        lblSelectMinutes.isHidden = false
        popUpButtonSelectMinutes.selectItem(at: 0)
        lblTitle.stringValue = "If you have something urgent, you can postpone Habits for few Minutes."
        btnPostpone.title = "Postpone Habit"
        btnAbortBreak.title = "Completely Skip"
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponeHabitsText") as? String ?? lblTitle.stringValue
            btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeHabitText") as? String ?? btnPostpone.title
            btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonCompletelySkipText") as? String ?? btnAbortBreak.title
        }
        
        btnPostpone.buttonColor = buttonBgColor.cgColor
        btnAbortBreak.buttonColor = NSColor.white.cgColor
        btnOkIWillDoBreak.isHidden = true
        btnPostpone.isHidden = false
        btnAbortBreak.isHidden = false
    }
    
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "[user-action] Ask postpone view - button Postpone Clicked")
        let postponeTime = Int(popUpButtonSelectMinutes.title) ?? 15
        if currentState == ._MORNING_HABIT_{
            if activityPostponeCount == 0 && postponeTime > 15{//when user clicks Please spare me for the first time, if the user selects to postpones for longer than 15 then the password will be asked.//#441
                
                if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipMorning{
                    self.view.removeFromSuperview()
                    getHabitsVcObject().showPasswordView()
                    enterPasswordVcObj?.parentVc = self
                    
                }else{
                    activityPostponeCount += 1
                    self.view.removeFromSuperview()
                    getHabitsVcObject().postponeMorningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                }
                
            }else{
                activityPostponeCount += 1
                self.view.removeFromSuperview()
                getHabitsVcObject().postponeMorningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
            }
            
        }else if currentState == ._EVENING_HABIT_{
            if activityPostponeCount == 0 && postponeTime > 15{//when user clicks Please spare me for the first time, if the user selects to postpones for longer than 15 then the password will be asked.//#441
                
                if shouldAskPassword(){
                    if isCutOffTimeGoing(){// changed in 2.27.422  : isHighPrioritySequenceGoing->isCutOffTimeGoing()// allready asked password if high Priority Sequence is Going
                        self.view.removeFromSuperview()
                        activityPostponeCount += 1
                        getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                        
                    }else{
                        if SettingsManagerObject.isPasswordRequireInSkipEvening{
                            self.view.removeFromSuperview()
                            getHabitsVcObject().showPasswordView()
                            enterPasswordVcObj?.parentVc = self
                        }else{
                            activityPostponeCount += 1
                            self.view.removeFromSuperview()
                            getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                        }
                    }
                }else{
                    activityPostponeCount += 1
                    self.view.removeFromSuperview()
                    getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                }
                
            }else{
                self.view.removeFromSuperview()
                activityPostponeCount += 1
                getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
            }
            
        }else if currentState == ._MICRO_BREAK_{
            if isShowingAskOfficeModeView{
                addLog(text: "Ask postpone view - Show Activity postpone View")
                showActivityostponeView()
            }else{//skip break activities
                addLog(text: "Ask postpone view - Postpone Break Activitie")
                activityPostponeCount += 1
                self.view.removeFromSuperview()
                getHabitsVcObject().postponeBreakActivitiesFor(minutes: postponeTime, secondsToPostpone: nil, isFromBreakWarningWindow: false)
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            self.view.removeFromSuperview()
            
            if shouldAskPassword() && !SettingsManagerObject.isEasySkipEnabled{
                var shouldShowPasswordView = false
                if cutOffTime != nil{
                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                    let currentDate = Date()
                    if currentDate > cutOffDate{
                        if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                            shouldShowPasswordView = true
                        }
                    }else{
                        if SettingsManagerObject.isPasswordRequireInSkipEvening{
                            shouldShowPasswordView = true
                        }
                    }
                }else{
                    if SettingsManagerObject.isPasswordRequireInSkipEvening{
                        shouldShowPasswordView = true
                    }
                }
                if shouldShowPasswordView{
                    getHabitsVcObject().showPasswordView()
                    enterPasswordVcObj?.parentVc = self
                }else{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: postponeTime, showAskIntention: true)
                }
            }else{
                getHabitsVcObject().postponeFocusSummaryFor(minutes: postponeTime, showAskIntention: true)
            }
        }

        
    }
    @IBAction func btnAbortBreakClicked(_ sender: Any) {
        if currentState == ._MICRO_BREAK_{
            if isShowingAskOfficeModeView{//enableOffcieMode
                addLog(text: "[user-action] Ask postpone view - Enabled Office Mode clicked")
                let filterArr = arrAllbreakActivities.filter { $0.isOfficeFriendly == true}
                if filterArr.count == 0{ //no activity found with isOfficeFriendly
                    //crete office friendy activity and start brek activity
                    addLog(text: "Ask postpone view - Create Office Activity And Enable Office Mode")
                    addOfficeFriendlyActivityInSettings()
                    self.view.removeFromSuperview()
                    getHabitsVcObject().enableOfficeModeAndRestartBreakActivities()
                    
                }else{
                    addLog(text: "Ask postpone view - Enabled Office Mode")
                    self.view.removeFromSuperview()
                    getHabitsVcObject().enableOfficeModeAndRestartBreakActivities()
                }
            }else{
                
                addLog(text: "[user-action] Ask postpone view - Skip Break Activitie Clicked")
                self.view.removeFromSuperview()
                getHabitsVcObject().postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil, isFromBreakWarningWindow: false)// we will use "postponeBreakActivitiesFor" function to skip break activity beacuse in "setActivitytimer" func there is no code to start morning habit again if break activity started from morning or evening routine(allowed app habit)
            }
        }else{
            addLog(text: "[user-action] Ask postpone view - button Abort Clicked")
            self.view.removeFromSuperview()
            getHabitsVcObject().processAborting()
        }
        
    }
    func addOfficeFriendlyActivityInSettings(){
        addLog(text: "addOfficeFriendlyActivityInSettings")//
        var jsonResult = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            //            jsonResult = dic
            if let data = stringDic.data(using: String.Encoding.utf8) {
                
                do {
                    jsonResult = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                    
                } catch let error as NSError {
                    print(error)
                }
            }
            
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            jsonResult = dicResult
                            print(jsonResult)
                        }
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        guard let mutableDic = jsonResult.mutableCopy() as? NSMutableDictionary else{
            return
        }
        let id = getUuid()
        var officeFriendlyActivityName = "Stand up and stretch"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            officeFriendlyActivityName = common.value(forKey: "officeFriendlyActivityName") as? String ?? officeFriendlyActivityName
        }
        
        let activity_sequence_id = arrAllbreakActivities.first?.activity_sequence_id ?? ""
        if var breakActivities = mutableDic.value(forKey: "break_activities") as? [NSDictionary] {
            let activityDic: NSMutableDictionary = ["id":id, "name":officeFriendlyActivityName, "duration_seconds":20, "is_office_friendly":true, "activity_sequence_id":activity_sequence_id]
            breakActivities.append(activityDic)
            mutableDic["break_activities"] = breakActivities
            
            arrAllbreakActivities.append(breakActivity(id:id,name: officeFriendlyActivityName, durationSeconds: 20, IncludeInEveryBreak: false, urlsArray: [], logQuantity:false, choiceType: ._NONE_, choices: [], logQuantityQuestion: "", openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: "",activity_sequence_id:activity_sequence_id, take_notes: "", text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[]))
            

            
            allApiObject.isSettingsValid(settings: mutableDic, isOnboarding:false, completionHandler: {dic,statusCode  in
                DispatchQueue.main.async {

                    
                    if dic == nil{
                        
                        
                    }else{
                        
                        if statusCode == 200{
                            do {
                                let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                
                                print(jsonResultData)
                                
                                if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                    UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                    
                                }
                            } catch let myJSONError {
                                print(myJSONError)
                            }
                            
                        }else{
 
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func btnOkIWillDoBreakClicked(_ sender: Any) {
        addLog(text: "[user-action] Ask postpone view - button Ok I Will Do activity Clicked")

        if currentState == ._MICRO_BREAK_{
            self.timer?.invalidate()
            self.timer = nil
            lblTimer.isHidden = true
            self.view.removeFromSuperview()
            getHabitsVcObject().showCloseButtons()
        }else{
            self.view.removeFromSuperview()
            getHabitsVcObject().abortCancel()
            self.timer?.invalidate()
            self.timer = nil
        }
    }

    func startTimer(duration:Int) {
        self.timer?.invalidate()
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

                self.lblTimer.isHidden = true
                
                if currentState == ._MICRO_BREAK_{
                    if SettingsManagerObject.isOfficeModeEnabled{
                        self.showActivityostponeView()
                    }else{
                        self.showAskOfficeModeView()
                    }
                }else if currentState == ._MORNING_HABIT_{
                    self.showHabitPostponeView()
                }else if currentState == ._EVENING_HABIT_{
                    self.showHabitPostponeView()
                }
            }
        }
    }
}
