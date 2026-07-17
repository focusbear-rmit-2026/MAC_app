//
//  shutOffTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/01/22.
//  
//

import Cocoa

class shutOffTimeVc: NSViewController {
    
    @IBOutlet weak var stackViewUnCancelRoutine: NSStackView!
    @IBOutlet weak var lblUncancelRoutine: NSTextField!
    @IBOutlet weak var btnUncancelEveningRoutine: underLineButton!
    @IBOutlet weak var bottomSpaceLblAlreadyUnlocked: NSLayoutConstraint!
    @IBOutlet weak var lblAlreadyUnlocked: NSTextField!
    @IBOutlet weak var lblSelectMinutesToUSe: NSTextField!
    @IBOutlet weak var popUpBtnDuration: NSPopUpButton!
    @IBOutlet weak var stackViewShutDown: NSStackView!
    @IBOutlet weak var btnSleep: Button!
    @IBOutlet weak var btnShutDownMac: Button!
    @IBOutlet weak var btnCompleteEveningRoutine: underLineButton!
    @IBOutlet weak var lblTitleUpEarly: NSTextField!
    @IBOutlet weak var btnWorkEmergency: Button!
    @IBOutlet weak var btnStartMorningRoutine: Button!
    @IBOutlet weak var boxUpEarly: NSBox!
    @IBOutlet weak var titleCenter: NSLayoutConstraint!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var lbltimer: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var lbl2: NSTextField!
    @IBOutlet weak var btnUnlock: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var btnGetAccessNow: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var step = 0
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    enum passwordReason:Int{
        case _ABORT_SHUTOFF_ = 11, _START_EVENING_ROUTINE_, _WORK_EMERGENCY_
    }
    var showPasswordReason = passwordReason._ABORT_SHUTOFF_
    var arrDurationSeconds = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblUncancelRoutine.stringValue = "(By the way, you cancelled your evening routine. if you changed your mind and want to do your evening habits click resume evening routine)"
        btnUncancelEveningRoutine.title = "Resume evening routine"
        
        
        lblSelectMinutesToUSe.stringValue = "Select duration for unlock:"
        btnShutDownMac.title = "Shut Down"
        btnSleep.title = "Sleep Mac"
        btnCompleteEveningRoutine.title = "Complete your evening routine"
        lblTitleUpEarly.stringValue = "Up early?"
        btnStartMorningRoutine.title = "Start morning routine"
        btnWorkEmergency.title = "Work emergency - start focusing"
        lblAlreadyUnlocked.stringValue = "You already unlocked for <DURATION> minutes"
        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
            lblTitleUpEarly.stringValue = shutOffTimeInfo.value(forKey: "titleUpEarly") as? String ?? lblTitleUpEarly.stringValue
            btnStartMorningRoutine.title = shutOffTimeInfo.value(forKey: "buttonStartMorningRoutineText") as? String ?? btnStartMorningRoutine.title
            btnWorkEmergency.title = shutOffTimeInfo.value(forKey: "buttonWorkEmergencyText") as? String ?? btnWorkEmergency.title
            btnCompleteEveningRoutine.title = shutOffTimeInfo.value(forKey: "buttonCompleteEveningRoutineText") as? String ?? btnCompleteEveningRoutine.title
            btnShutDownMac.title = shutOffTimeInfo.value(forKey: "buttonShutDownText") as? String ?? btnShutDownMac.title
            btnSleep.title = shutOffTimeInfo.value(forKey: "buttonSleepText") as? String ?? btnSleep.title
            lblSelectMinutesToUSe.stringValue = shutOffTimeInfo.value(forKey: "selectUnlockMinutesText") as? String ?? lblSelectMinutesToUSe.stringValue
            lblAlreadyUnlocked.stringValue = shutOffTimeInfo.value(forKey: "alreadyUnlockedText") as? String ?? lblAlreadyUnlocked.stringValue
            lblUncancelRoutine.stringValue = shutOffTimeInfo.value(forKey: "cancelledEveningRoutineReminderText") as? String ?? lblUncancelRoutine.stringValue
            btnUncancelEveningRoutine.title = shutOffTimeInfo.value(forKey: "buttonResumeEveningRoutine") as? String ?? btnUncancelEveningRoutine.title
        }
        
        lblAlreadyUnlocked.stringValue = lblAlreadyUnlocked.stringValue.replacingOccurrences(of: "<DURATION>", with: "30")
        
        btnShutDownMac.isSecondaryButton = true
        popUpBtnDuration.removeAllItems()
        popUpBtnDuration.addItems(withTitles: ["15 \(minutesText)", "30 \(minutesText)", "1 \(hourText)", "2 \(hoursText)", "4 \(hoursText)", "8 \(hoursText)"])
        arrDurationSeconds = [900, 1800, 3600, 7200, 14400, 28800]
        stackViewUnCancelRoutine.isHidden = true
        
        btnStartMorningRoutine.isSecondaryButton = true
        btnWorkEmergency.isSecondaryButton = true
        btnSleep.isSecondaryButton = true
        
        
        btnShutDownMac.title = "⏻  " + btnShutDownMac.title
        btnSleep.title = "💤  " + btnSleep.title
        btnStartMorningRoutine.title = "☀️  " + btnStartMorningRoutine.title
        btnWorkEmergency.title = "🔨  " + btnWorkEmergency.title
        
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }
    
    override func viewWillAppear() {
        resetView()
    }
    
    override func viewWillDisappear() {
        timer?.invalidate()
        timer = nil
    }
    
    func resetView(){
        bottomSpaceLblAlreadyUnlocked.constant = 30
        lblAlreadyUnlocked.isHidden = true
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{//} && isCutOffTimeGoing(){
            // if user has not unlocked today
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastShutdownAbortedDate) as? Date{
                if Date().compare(date) == .orderedAscending {
                    lblAlreadyUnlocked.isHidden = false
                }
            }
        }
        
        titleCenter.constant = 80
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Yawn_small")
            imgViewGif.animates = true
        }
        
        lblTitle.stringValue = "Time to wind down"
        btnGetAccessNow.title = "Unlock computer"

        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
            btnGetAccessNow.title = shutOffTimeInfo.value(forKey: "buttonUnlockComputer") as? String ?? btnGetAccessNow.title
        }
        
        var timeFormat = "h:mm a"
        if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
            print(dict)
            if let isShow24Hour = dict["Show24Hour"] as? Bool {
                if isShow24Hour{
                    timeFormat = "H:mm"
                }
            }
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        if let cutOffTime = cutOffTime{
            shutOffdate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
        }
        
        let startDateString = getStringFromDate(date: startDate, dateFormat: timeFormat)
        let shutOffDateString = getStringFromDate(date: shutOffdate, dateFormat: timeFormat)
        
        
        lblSubTitle.stringValue = "You told me you wanted to stay off your computer from \(shutOffDateString) to \(startDateString). Enjoy your evening and sleep well. Look forward to helping you with your morning routine tomorrow."
        
        
        
        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
            if let title = shutOffTimeInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if var subTitle = shutOffTimeInfo.value(forKey: "subTitle") as? String{
                subTitle = subTitle.replacingOccurrences(of: "<SHUTOFFTIME>", with: "\(shutOffDateString)")
                subTitle = subTitle.replacingOccurrences(of: "<STARTTIME>", with: "\(startDateString)")
                lblSubTitle.stringValue = subTitle
            }
            if let buttonAbortText = shutOffTimeInfo.value(forKey: "buttonAbortText") as? String{
               // btnGetAccessNow.title = buttonAbortText
            }
        }
        
        lbl2.isHidden = true
        scrollView.isHidden = true
        btnUnlock.isHidden = true
        btnGetAccessNow.isHidden = false
        stackViewShutDown.isHidden = false
        boxUpEarly.isHidden = true
        lbltimer.isHidden = true
        step = 0
        checkUpEarlyTime()
        
        popUpBtnDuration.isHidden = true
        lblSelectMinutesToUSe.isHidden = true
        
        btnCompleteEveningRoutine.isHidden = true
        
        //Evening routine aborted. reason:- four hours remaining in start morning routines and evening routine is not started yet.
        if arrAllDaysEveningHabits.count != 0{//} && !iseveningHabitAlreadyShowed {
            if UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date == nil{
                btnCompleteEveningRoutine.isHidden = false
                return;
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                    if Date().compare(date) == .orderedDescending {
                        btnCompleteEveningRoutine.isHidden = false
                        return;
                    }else{
                        btnCompleteEveningRoutine.isHidden = true
                        addLog(text: "Evening habits already shown for today - skipping.")
                    }
                }
            }
        }
        
        updateUncancelRoutineButtonVisibility()
    }
    
    @objc func viewDidResize(){
        if self.view.frame.height < 600{
            lblSubTitle.font = getRegularFont(size: 18)
            lblUncancelRoutine.font = getRegularFont(size: 12)
            stackViewUnCancelRoutine.spacing = 4
            btnUncancelEveningRoutine.font = getRegularFont(size: 12)
        }else if self.view.frame.height < 700{
            lblSubTitle.font = getRegularFont(size: 19)
            lblUncancelRoutine.font = getRegularFont(size: 15)
            stackViewUnCancelRoutine.spacing = 6
            btnUncancelEveningRoutine.font = getRegularFont(size: 15)
        }else{
            lblSubTitle.font = getRegularFont(size: 22)
            lblUncancelRoutine.font = getRegularFont(size: 16)
            stackViewUnCancelRoutine.spacing = 10
            btnUncancelEveningRoutine.font = getRegularFont(size: 16)
        }
    }
    
    @IBAction func btnCompleteEveningRoutineClicked(_ sender: Any) {
        currentState = ._NOTHING_
        UserDefaults.standard.set(true, forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        appdelegate?.backgroundThread()
    }
    
    func checkUpEarlyTime(){
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        let hoursToAllowUserToDoHabitsBeforeMorningHabitTime = 4
        var fourHourBeforeStartTime = startDate.addingTimeInterval(TimeInterval((0-hoursToAllowUserToDoHabitsBeforeMorningHabitTime) * 60 * 60))
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate
            fourHourBeforeStartTime = startDate.addingTimeInterval(TimeInterval((0-hoursToAllowUserToDoHabitsBeforeMorningHabitTime) * 60 * 60))
        }
        if Date() > fourHourBeforeStartTime{
            boxUpEarly.isHidden = false
            bottomSpaceLblAlreadyUnlocked.constant = 10
        }
    }
    
    /// Unlocking the computer past cutoff is a "postpone evening routine after cutoff" action, so this
    /// honours that specific rule too — not only the abort-shutoff one. Without this, a user with only
    /// the postpone-after-cutoff password rule on could unlock past cutoff with no password. Shared by
    /// every shutoff-screen button that can unlock/postpone past the cutoff (Unlock computer, Work
    /// emergency, Start morning routine early) so none of them can bypass the rule the other two honour.
    private func shouldGateShutoffAction() -> Bool {
        let postponeAfterCutoff = isCutOffTimeGoing() && SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff
        return SettingsManagerObject.isPasswordRequireInAbortShutoff || postponeAfterCutoff
    }

    @IBAction func btnGetAccessNowClicked(_ sender: Any) {
        addLog(text:"[user-action] btnGetAccessNowClicked")
        
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
            // if user has not unlocked today
            var shouldAbortShutDownInOneClick = true
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastShutdownAbortedDate) as? Date{
                if Date().compare(date) == .orderedAscending {
                    shouldAbortShutDownInOneClick = false
                }
            }
            if shouldAbortShutDownInOneClick{
                addLog(text: "emergency Start Done for 30 minutes for first time today")
                
                let alert = NSAlert()
                alert.setSharingType()
                alert.messageText = "Unlocking for 30 minutes."
                if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
                    alert.messageText = shutOffTimeInfo.value(forKey: "unlockingFirstTimeText") as? String ?? alert.messageText
                }
                
                alert.addButton(withTitle: buttonOkText)
                NSApplication.shared.activate(ignoringOtherApps: true)
                alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
                    getHabitsVcObject().hideCloseButtons()
                    getHabitsVcObject().removeSubViews()
                    currentState = ._NOTHING_
                    mainWindowControllerObj?.window?.close()
                    hideBlankWindowInSecondaryMonitor()
                    leftMenuVcObj?.habitOver()

                    let shutdownAbortedTillTime = Calendar.current.date(byAdding: .second, value: 1800, to: Date())! // 30 minutes
                    UserDefaults.standard.set(shutdownAbortedTillTime, forKey: kUserdefaultsShutdownAborted)
                    
                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                    
                    let curreentDate = Date()
                    if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastShutdownAbortedDate)
                    }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastShutdownAbortedDate)
                    }
                })
                return;
            }
        }
        
        if shouldAskPassword(){
            if shouldGateShutoffAction(){
                showPasswordReason = passwordReason._ABORT_SHUTOFF_
                mainViewControllerObj!.showPasswordView()
            }else{
                getAccessNowClicked()
            }
        }else{
            getAccessNowClicked()
        }
    }
    
    func passwordEnteredSuccessfully(){
        if showPasswordReason == ._ABORT_SHUTOFF_{
            getAccessNowClicked()
        }else if showPasswordReason == ._START_EVENING_ROUTINE_{
            startMorningRoutineClicked()
        }else if showPasswordReason == ._WORK_EMERGENCY_{
            workEmergencyClicked()
        }
    }
    
    func getAccessNowClicked(){
        stackViewUnCancelRoutine.isHidden = true
        btnCompleteEveningRoutine.isHidden = true
        titleCenter.constant = 0
        btnGetAccessNow.isHidden = true
        lblAlreadyUnlocked.isHidden = true
        stackViewShutDown.isHidden = true
        boxUpEarly.isHidden = true
        scrollView.isHidden = false
        lbl2.isHidden = false
        lbltimer.isHidden = false
        btnUnlock.isHidden = false
        
        lblTitle.stringValue = "Emergency?"
        lblSubTitle.stringValue = "Are you sure you want to do this? Using your computer late at night could mess up your sleep. Please take 10 seconds to reflect on whether this is really an emergency or whether it can wait."
        lbl2.stringValue = "Feel free to write an explanation here:"
        btnUnlock.title = "Cancel"
        
        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
            if let shutOffAbortInfo = shutOffTimeInfo.value(forKey: "shutOffAbortInfo") as? NSDictionary{
                if let title = shutOffAbortInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = shutOffAbortInfo.value(forKey: "subTitle") as? String{
                    lblSubTitle.stringValue = subTitle.replacingOccurrences(of: "30", with: "10")
                }
                if let shareFeedbackText = shutOffAbortInfo.value(forKey: "shareFeedbackText") as? String{
                    lbl2.stringValue = shareFeedbackText
                }
                btnUnlock.title = buttonCancelText
            }

        }
        imgViewGif.image = nil
        step = 1
        startTimer(duration: 10)
    }
    

    
    @IBAction func btnUnlockClicked(_ sender: Any) {
        addLog(text:"[user-action] btnUnlockClicked")
        if step == 1{
            //cancel aborting shutoff process
            currentState = ._NOTHING_//need to set nothing here because in shutOffMac() func if already shutoff state is set then return from fuction
            getHabitsVcObject().shutOffMac()
            timer?.invalidate()
            timer = nil
        }else if step == 2{
            titleCenter.constant = 0
            self.popUpBtnDuration.isHidden = true
            self.lblSelectMinutesToUSe.isHidden = true
            var startTimeHour = "\(startTime?.hour ?? 0)"
            if startTimeHour.count == 1{
                startTimeHour = "0\(startTimeHour)"
            }
            
            var startTimeMinute = "\(startTime?.minute ?? 0)"
            if startTimeMinute.count == 1{
                startTimeMinute = "0\(startTimeMinute)"
            }
            lblSubTitle.stringValue = "Sorry to hear that something bad has happened and you absolutely need to use your computer late at night. We’re unlocking your machine now. Your morning routine will still activate at \(startTimeHour):\(startTimeMinute). Hope you’re able to catch up on sleep during the day.\n\n\nUnlocking in" 
            
            
            if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
                if let shutOffAbortDoneInfo = shutOffTimeInfo.value(forKey: "shutOffAbortDoneInfo") as? NSDictionary{
                    if var subTitle = shutOffAbortDoneInfo.value(forKey: "subTitle") as? String, let unlockingText = shutOffAbortDoneInfo.value(forKey: "unlockingText") as? String{

                        subTitle = subTitle.replacingOccurrences(of: "<STARTTIME>", with: "\(startTimeHour):\(startTimeMinute)")
                        lblSubTitle.stringValue = subTitle + "\n\n\n" + unlockingText
                    }
                }

            }
            
            lbl2.stringValue = ""
            mainWindowControllerObj!.window!.styleMask.remove(.resizable)// bcos user can togle resize at close time and that can make problems
            startTimer(duration: 5)
            self.btnUnlock.isHidden = true
            scrollView.isHidden = true
        }
    }
    
    
    
    func startTimer(duration:Int) {
        lbltimer.isHidden = false
        popUpBtnDuration.isHidden = true
        lblSelectMinutesToUSe.isHidden = true
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
        timer?.invalidate()
        timer = nil
        self.lbltimer.stringValue = "\(minute):\(second)"
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
            self.lbltimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            if step == 1{
                self.step = 2
                self.timer?.invalidate()
                self.timer = nil
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.btnUnlock.title = "Unlock"
                        if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
                            if let shutOffAbortInfo = shutOffTimeInfo.value(forKey: "shutOffAbortInfo") as? NSDictionary{
                                if let buttonUnlockText = shutOffAbortInfo.value(forKey: "buttonUnlockText") as? String{
                                    self.btnUnlock.title = buttonUnlockText
                                }
                            }
                            if isCutOffTimeGoing(){
                                self.popUpBtnDuration.isHidden = false
                                self.lblSelectMinutesToUSe.isHidden = false
                            }else{
                                self.popUpBtnDuration.isHidden = true
                                self.lblSelectMinutesToUSe.isHidden = true
                            }

                        }
                        self.lbltimer.isHidden = true
                    }
                }
            }else{
                self.timer?.invalidate()
                timer = nil
                self.step = 3
                DispatchQueue.main.async {
                    if isCutOffTimeGoing(){
                        allApiObject.capturePosthog(event: "shutoff-aborted", metadata: ["intention":self.textView.string, "duration": self.arrDurationSeconds[self.popUpBtnDuration.indexOfSelectedItem]])
                    }else{
                        allApiObject.capturePosthog(event: "shutoff-aborted", metadata: ["intention":self.textView.string])
                    }
                    
                    self.emergencyStartDone()
                }
            }
        }
    }
    
    func workEmergencyClicked(){
        if SettingsManagerObject.isGeekModeEnabled{
            //Bug fixed in v3.32.487. Previously, emergencyStartDone() was being called, which caused issues during cutoff time because that function contains additional checks. This has now been corrected.
            getHabitsVcObject().hideCloseButtons()
            getHabitsVcObject().removeSubViews()
            currentState = ._NOTHING_
            hideBlankWindowInSecondaryMonitor()
            leftMenuVcObj?.habitOver()

            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsShutdownAborted)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsShutdownAborted)
            }
            
            appdelegate?.menuShowPomodoroModeView()
        }else{
            btnGetAccessNowClicked(self)
        }
    }
    
    func startMorningRoutineClicked(){
        var jsonResult = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
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

        let startup_time = getStringFromDate(date: Date(), dateFormat: "HH:mm")
        mutableDic["startup_time"] = startup_time
        startTimeString = startup_time
        startTime = getTimeFromString(val: startup_time)
        appdelegate?.backgroundThread()
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
        applastSettingsGetTime = Date()
    }
    
    @IBAction func btnWorkEmergencyClicked(_ sender: Any) {
        addLog(text: "[user-action] btnWorkEmergencyClicked")
        if shouldAskPassword(){
            if shouldGateShutoffAction(){
                showPasswordReason = passwordReason._WORK_EMERGENCY_
                mainViewControllerObj!.showPasswordView()
            }else{
                workEmergencyClicked()
            }
        }else{
            workEmergencyClicked()
        }
    }

    @IBAction func btnStartMorningRoutineClicked(_ sender: Any) {
        addLog(text: "[user-action] btnStartMorningRoutineClicked")
        if shouldAskPassword(){
            if shouldGateShutoffAction(){
                showPasswordReason = passwordReason._START_EVENING_ROUTINE_
                mainViewControllerObj!.showPasswordView()
            }else{
                startMorningRoutineClicked()
            }
        }else{
            startMorningRoutineClicked()
        }
    }
    
    @IBAction func btnShutDownMacClicked(_ sender: Any) {
        addLog(text: "[user-action] btnShutDownMacClicked")
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in 
            shutDownMac()
            print("shut down mac")
        }
        
        // check after 2 minutes is app alive thrn show window again
        Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { timer in
            currentState = ._NOTHING_
        }
    }
    
    @IBAction func btnSleepClicked(_ sender: Any) {
        addLog(text: "[user-action] btnSleepClicked")
        sleepMac()
    }
    
    @IBAction func popUpBtnDurationClicked(_ sender: Any) {
        
    }
    
    func emergencyStartDone(){
        addLog(text: "emergencyStartDone")
        getHabitsVcObject().hideCloseButtons()
        getHabitsVcObject().removeSubViews()
        currentState = ._NOTHING_
        hideBlankWindowInSecondaryMonitor()
        leftMenuVcObj?.habitOver()
        
        if SettingsManagerObject.isGeekModeEnabled{
            appdelegate?.menuShowPomodoroModeView()
        }
        if !isCutOffTimeGoing(){
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsShutdownAborted)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsShutdownAborted)
            }
        }else{
            let shutdownAbortedTillTime = Calendar.current.date(byAdding: .second, value: arrDurationSeconds[popUpBtnDuration.indexOfSelectedItem], to: Date())!
            UserDefaults.standard.set(shutdownAbortedTillTime, forKey: kUserdefaultsShutdownAborted)
        }
    }
    

    @IBAction func btnUncancelEveningRoutineClicked(_ sender: Any) {
        mainViewControllerObj?.showLoaderView()
        allApiObject.uncompleteCurrentSequence(activity_sequence_id: arrFilteredEveningHabits.first?.activity_sequence_id ?? "", completionHandler: {json in
            if json != nil{
                DispatchQueue.main.async {
                    mainViewControllerObj?.hideLoaderView()
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsEveningHabitsShowedTillDate)
                    currentState = ._NOTHING_
                    appdelegate!.backgroundThread()
                }
            }
        })
    }
    
    func updateUncancelRoutineButtonVisibility() {
        stackViewUnCancelRoutine.isHidden = true
        let routineType = "evening_routine"
        let sequenceIdToCheck = arrFilteredEveningHabits.first?.activity_sequence_id ?? ""
        
        allApiObject.getLastActivityInfo { json in
            
            guard
                let todayRoutineProgress = json?["today_routine_progress"] as? NSDictionary,
                let routine = todayRoutineProgress[routineType] as? NSDictionary,
                let todaySequenceId = routine["sequence_id"] as? String,
                let status = routine["status"] as? String,
                let wasForceCompleted = routine["was_force_completed"] as? Bool
            else {
                return
            }
            
            let shouldShowButton =
                todaySequenceId == sequenceIdToCheck &&
                status.lowercased() == "completed" &&
                wasForceCompleted
            
            DispatchQueue.main.async { [self] in
                self.stackViewUnCancelRoutine.isHidden = !shouldShowButton
            }
        }
    }
}
