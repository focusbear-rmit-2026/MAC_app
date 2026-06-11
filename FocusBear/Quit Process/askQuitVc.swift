//
//  askQuitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askQuitVc: NSViewController {
    
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var popUpBtnHour: NSPopUpButton!
    @IBOutlet weak var lblSelectHours: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnAppQuit: Button!
    @IBOutlet weak var btnBreakFourHours: Button!
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    
    @IBOutlet weak var btnSkip: underLineButton!
    
    var buttonBreakOneHourText = "Turn it off for 1 hour"
    var buttonBreakFewHourText = "Turn it off for <HOUR> hours"
    var buttonBreakFewMinutesText = "Turn it off for <MINUTE> minutes"
    
    
    var buttonPostponeOneHourText = "Postpone habits for 1 hour"
    var buttonPostponeFewHourText = "Postpone habits for <HOUR> hours"
    var buttonPostponeFewMinutesText = "Postpone habits for <MINUTE> minutes"
    
    var enterPasswordVcObj: enterPasswordVc?
    
    let oneHourIndex = 3
    let fiveMinutesIndex = 0
    let fifteenMinutesIndex = 1
    let thirtyMinutesIndex = 2
    let twoHourIndex = 4
    let fourHourIndex = 5
    let twelveHourIndex = 6
    let twentyFourHourIndex = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblSelectHours.stringValue = "Select hours to turn it off"
        
        lblTitle.stringValue = "Quitting.."
        lblSubTitle.stringValue = "Do you want to quit the app completely or just take a break for a few hours?"
        btnBreakFourHours.title = "Give me a break for 4hrs"
        btnAppQuit.title = "Turn it off completely - I'll turn it back on when I'm ready"
        
        
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingTitle = quitInfo.value(forKey: "quittingTitle") as? String{
                lblTitle.stringValue = quittingTitle
            }
            if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                lblSubTitle.stringValue = askQuitVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
                btnBreakFourHours.title = askQuitVcInfo.value(forKey: "buttonDiableAppText") as? String ??  btnBreakFourHours.title
                btnAppQuit.title = askQuitVcInfo.value(forKey: "buttonQuitText") as? String ?? btnAppQuit.title
                lblSelectHours.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblSelectHours.stringValue
                buttonBreakOneHourText =  askQuitVcInfo.value(forKey: "buttonBreakOneHourText") as? String ?? buttonBreakOneHourText
                buttonBreakFewHourText =  askQuitVcInfo.value(forKey: "buttonBreakFewHourText") as? String ?? buttonBreakFewHourText
                buttonBreakFewMinutesText =  askQuitVcInfo.value(forKey: "buttonBreakFewMinutesText") as? String ?? buttonBreakFewMinutesText
                
                buttonPostponeOneHourText =  askQuitVcInfo.value(forKey: "buttonPostponeOneHourText") as? String ?? buttonPostponeOneHourText
                buttonPostponeFewHourText =  askQuitVcInfo.value(forKey: "buttonPostponeFewHourText") as? String ?? buttonPostponeFewHourText
                buttonPostponeFewMinutesText =  askQuitVcInfo.value(forKey: "buttonPostponeFewMinutesText") as? String ?? buttonPostponeFewMinutesText
                
            }
        }
        
        btnAppQuit.isSecondaryButton = true
        popUpBtnHour.removeAllItems()
        popUpBtnHour.addItems(withTitles: ["5 \(minutesText)", "15 \(minutesText)", "30 \(minutesText)", "1 \(hourText)", "2 \(hoursText)", "4 \(hoursText)", "12 \(hoursText)", "24 \(hoursText)"])
        
    }
    
    var isPostponeInfoShowing = false
    //if easy postpone is going to show then close quit window and if easy postpone window is allready visible and if user click on quit then dont show about postpone in quit
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgView.image = nil
            imgView.isHidden = true
        }else{
            imgView.image = NSImage(named: "Crying_small")
            imgView.animates = true
            imgView.isHidden = false
        }
        var isEasyPostponeWindowVisible = false
        
//        if easyPostponeWcObj != nil{
//            if easyPostponeWcObj?.window?.isVisible ?? false{
//                isEasyPostponeWindowVisible = true
//            }
//        }
        if easyPostponeVcObj != nil{
            if easyPostponeVcObj?.isViewVisible ?? false{
                isEasyPostponeWindowVisible = true
            }
        }
        
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_ && !isEasyPostponeWindowVisible{
            popUpBtnHour.selectItem(at: 0)
            var habitName = ""
            
            if currentHabitPlaying != nil{
                habitName = currentHabitPlaying?.name ?? ""
            }
            var subTitlePostpone = "You're in the middle of your <ROUTINE> routine. Do you want to skip/postpone <HABITNAME> or turn the app off completely?"
            var routineMorningText = "morning"
            var routineEveningText = "evening"
            lblSelectHours.stringValue =  "Postpone it for"
            var skipHabitText = "Skip <HABITNAME>"
            
            if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                    subTitlePostpone = askQuitVcInfo.value(forKey: "subTitlePostpone") as? String ?? subTitlePostpone
                    lblSelectHours.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblSelectHours.stringValue
                    routineMorningText = askQuitVcInfo.value(forKey: "routineMorningText") as? String ?? routineMorningText
                    routineEveningText = askQuitVcInfo.value(forKey: "routineEveningText") as? String ?? routineEveningText
                    skipHabitText = askQuitVcInfo.value(forKey: "buttonSkipText") as? String ?? skipHabitText
                    lblSelectHours.stringValue = askQuitVcInfo.value(forKey: "selectPostponeHoursText") as? String ?? lblSelectHours.stringValue
                }
            }
            
            
            var routineType = ""
            if currentState == ._MORNING_HABIT_{
                routineType = routineMorningText
            }else if currentState == ._EVENING_HABIT_{
                routineType = routineEveningText
            }
            subTitlePostpone = subTitlePostpone.replacingOccurrences(of: "<ROUTINE>", with: routineType)
            subTitlePostpone = subTitlePostpone.replacingOccurrences(of: "<HABITNAME>", with: habitName)
            
            lblSubTitle.stringValue = subTitlePostpone
            btnSkip.isHidden = false
            
            btnSkip.title = skipHabitText.replacingOccurrences(of: "<HABITNAME>", with: habitName)
            isPostponeInfoShowing = true
        }else{
            btnSkip.isHidden = true
            popUpBtnHour.selectItem(at: 3)
            lblSubTitle.stringValue = "Do you want to quit the app completely or just take a break for a few hours?"
            if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                    lblSubTitle.stringValue = askQuitVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
                    lblSelectHours.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblSelectHours.stringValue
                }
            }
            isPostponeInfoShowing = false
        }
        popUpBtnHourClicked(self)
    }
    
    override func viewWillDisappear() {
        if enterPasswordVcObj != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                enterPasswordVcObj?.view.removeFromSuperview()
            }
        }
    }
    
    @IBAction func popUpBtnHourClicked(_ sender: Any) {
        let index = popUpBtnHour.indexOfSelectedItem
        if index == oneHourIndex{
            if isPostponeInfoShowing{
                btnBreakFourHours.title = buttonPostponeOneHourText
            }else{
                btnBreakFourHours.title = buttonBreakOneHourText
            }
        }else if index < oneHourIndex{
            var minutes = 30
            switch index {
            case fiveMinutesIndex:
                minutes = 5
            case fifteenMinutesIndex:
                minutes = 15
            case thirtyMinutesIndex:
                minutes = 30
            default:
                minutes = 30
            }
            if isPostponeInfoShowing{
                btnBreakFourHours.title = buttonPostponeFewMinutesText.replacingOccurrences(of: "<MINUTE>", with: "\(minutes)")
            }else{
                btnBreakFourHours.title = buttonBreakFewMinutesText.replacingOccurrences(of: "<MINUTE>", with: "\(minutes)")
            }
        }else{
            var hour  = 4
            switch index {
            case twoHourIndex:
                hour = 2
            case fourHourIndex:
                hour = 4
            case twelveHourIndex:
                hour = 12
            case twentyFourHourIndex:
                hour = 24
            default:
                hour = 4
            }
            
            if isPostponeInfoShowing{
                btnBreakFourHours.title = buttonPostponeFewHourText.replacingOccurrences(of: "<HOUR>", with: "\(hour)")
            }else{
                btnBreakFourHours.title = buttonBreakFewHourText.replacingOccurrences(of: "<HOUR>", with: "\(hour)")
            }
            
        }
    }
    
    func getMinutes()-> Int{
        let index = popUpBtnHour.indexOfSelectedItem
        var minutes = 0
        
        if index == oneHourIndex{
            minutes = 60
        }else if index < oneHourIndex{
            switch index {
            case fiveMinutesIndex:
                minutes = 5
            case fifteenMinutesIndex:
                minutes = 15
            case thirtyMinutesIndex:
                minutes = 30
            default:
                minutes = 30
            }
        }else{
            switch index {
            case twoHourIndex:
                minutes = 120
            case fourHourIndex:
                minutes = 240
            case twelveHourIndex:
                minutes = 720
            case twentyFourHourIndex:
                minutes = 1440
            default:
                minutes = 4
            }
        }
        return minutes
    }
    
    @IBAction func btnBreakFourHoursClicked(_ sender: Any) {
        addLog(text: "[user-action] button BreakFourHours Clicked")
        if isPostponeInfoShowing{//
            getHabitsVcObject().refreshLastPostponeCount()
            if SettingsManagerObject.isEasySkipEnabled{
                postponeHabits()
            }else{
                if shouldAskPassword(){
                    if currentState == ._MORNING_HABIT_ {
                        if SettingsManagerObject.isPasswordRequireInSkipMorning{
                            showPasswordView()
                        }else{
                            postponeHabits()
                        }
                    }else if currentState == ._EVENING_HABIT_{
                        if isHighPrioritySequenceGoing{
                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                showPasswordView()
                            }else{
                                postponeHabits()
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                showPasswordView()
                            }else{
                                postponeHabits()
                            }
                        }
                    }
                }else{
                    postponeHabits()
                }
            }
        }else{
            if SettingsManagerObject.isStrictnessLevelSuperGentle(){//Ultra low friction level #1357
                addLog(text: "askQuitVc:- strictness level is super gentle")
                deavtivateApp()
            }else{
                if shouldAskPassword(){
                    if SettingsManagerObject.isPasswordRequireInQuitApp{
                        showPasswordView()
                        self.enterPasswordVcObj?.isShowingForDeactivatingApp = true
                        return;
                    }
                }
                tryDeactivateApp()
            }
            
        }
    }
    
    func tryDeactivateApp(){
        addLog(text: "askQuitVc:- tryDeactivateApp")
        if currentState == ._MORNING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_{
            let alert = NSAlert()
            alert.setSharingType()
            alert.alertStyle = .informational
            var titleSkipMorningHabit = "Do you want to do your morning routine later today or skip it?"
            var buttonSkipMorningHabitText = "Skip my morning routine"
            var buttonWillDoMorningHabitText = "I'll do my morning routine"
            if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                    titleSkipMorningHabit = askQuitVcInfo.value(forKey: "titleSkipMorningHabit") as? String ?? titleSkipMorningHabit
                    buttonSkipMorningHabitText =  askQuitVcInfo.value(forKey: "buttonSkipMorningHabitText") as? String ?? buttonSkipMorningHabitText
                    buttonWillDoMorningHabitText =  askQuitVcInfo.value(forKey: "buttonWillDoMorningHabitText") as? String ?? buttonWillDoMorningHabitText
                }
            }
            alert.messageText = titleSkipMorningHabit
            
            alert.addButton(withTitle: buttonWillDoMorningHabitText)
            alert.addButton(withTitle: buttonSkipMorningHabitText)
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn){
                    let sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
                    allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
                        print("forceCompleteCurrentSequence success")
                    })
                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                    isHabitAlreadyShowed = true
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    addLog(text: "morning habit skipped by user while turn it off for 4 hours")
                    
                    self.deavtivateApp()
                }else{
                    self.deavtivateApp()
                }
            })
        }else{
            deavtivateApp()
        }
    }
    
    func deavtivateApp(){
        let minutes = getMinutes()
        let date = Date().addingTimeInterval(TimeInterval(minutes * 60))//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
        UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "App Deactivated for \(minutes) minutes - I've got an emergency")
        allApiObject.capturePosthog(event: "turn-it-off-for-x-duration", metadata: [:])
        addEntryInStatsCsv(logType: "quit abort", activity: "quit", durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "", tags:"")
        loader.startAnimation(self)
        btnBreakFourHours.isEnabled = false
        DispatchQueue.global().async {//waiting for posthog
            sleep(1)
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                mainViewControllerObj?.disableApp()
            }
        }
    }
    
    func showPasswordView(){
        addLog(text: "askQuitVc:- showPasswordView")
        if self.enterPasswordVcObj == nil{
            self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
        }
        
        self.view.addSubview(self.enterPasswordVcObj!.view)
        self.view.addConstraints(subView: self.enterPasswordVcObj!.view)
        self.enterPasswordVcObj?.removeConstraints()
        self.enterPasswordVcObj?.isShowingForDeactivatingApp = false
    }
    
    func postponeHabits(){
        addLog(text: "askQuitVc:- postponeHabits")
        let minutes = getMinutes()
        getHabitsVcObject().stopActivityCountDownTimer()
        
        setDocBarTo(isHide: false)
        if currentHabitPlaying != nil{
            closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
        }
        getHabitsVcObject().stopActivityTimer()
        if currentHabitPlaying != nil{
            closePupUpBlockIfVisible()
        }
        if currentState == ._MORNING_HABIT_{
            getHabitsVcObject().postponeMorningHabitFor(minutes: minutes, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
        }else if currentState == ._EVENING_HABIT_{
            getHabitsVcObject().postponeEveningHabitFor(minutes: minutes, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
        }
        
        if relaxModeWcObj != nil{
            if relaxModeWcObj!.window?.isVisible ?? false{
                relaxModeVcObj?.closeTimerBox()
            }
        }
        self.view.window?.close()
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] button Skip Clicked")
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_{
            isLastActivityStoppedInRunningState = true
            lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            timerViewcontrollerObj?.btnPauseClicked(self)
            timerViewcontrollerObj?.menuItemSkipHabitClicked()
            leftMenuVcObj?.showHabitsView()
            leftMenuVcObj?.disableAllExceptHabitTab()
            
            closeSmallCountDownTimerBoxIfVisible()
            
            if relaxModeWcObj != nil{
                if relaxModeWcObj!.window?.isVisible ?? false{
                    relaxModeVcObj?.closeTimerBox()
                }
            }
            
            self.view.window?.close()
        }else{
            self.view.window?.close()
        }
    }
    
    @IBAction func btnAppQuitClicked(_ sender: Any) {
        addLog(text: "[user-action] - Turn it off completely Clicked")
        
        if SettingsManagerObject.isStrictnessLevelSuperGentle(){//Ultra low friction level #1357
            addLog(text: "askQuitVc:- strictness level is super gentle")
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"super gentle quit", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled(), "feedback": ""])
            loader.startAnimation(self)
            btnAppQuit.isEnabled = false
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                self.loader.stopAnimation(self)
                self.btnAppQuit.isEnabled = true
                UserDefaults.standard.set("super gentle quit", forKey: kUserDefaultsLastQuitReason)
                appdelegate?.quitAppForUser()
            }
        }else{
            loader.startAnimation(self)
            allApiObject.getuserLongTermGoals(completionHandler: {arrGoals in
                DispatchQueue.main.async {
                    self.loader.stopAnimation(self)
                    if arrGoals != nil{
                        if arrGoals!.count != 0{
                            getLongTermGoalsVcObject().arrGoals = arrGoals!
                            self.presentAsSheet(getLongTermGoalsVcObject())
                            return;
                        }
                    }
                    showQuittingConfirmView()
                }
            })
        }
    }
    
}
