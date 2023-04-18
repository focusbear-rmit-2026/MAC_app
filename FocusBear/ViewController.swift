//
//  ViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa


class ViewController: NSViewController {
    
    @IBOutlet weak var boxMinimize: NSBox!
    @IBOutlet weak var stackViewTopButtons: NSStackView!
    @IBOutlet weak var btnAbort: Button!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var boxContainer: customBoxBg!
    
    var topButtonsTrackingArea: NSTrackingArea?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblMessage.stringValue = "OK - Stay focused throughout the day!"
        lblMessage.isHidden = true
        btnAbort.title = "Please spare me"
        btnAbort.borderWidth = 2
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
            btnAbort.title = common.value(forKey: "buttonAbortText") as? String ?? btnAbort.title
        }
        isMainWindowLodded = true
        
        
        btnAbort.buttonColor = NSColor(red: 255/255, green: 244/255, blue: 233/255, alpha: 1).cgColor
        
        topButtonsTrackingArea = NSTrackingArea.init(rect: stackViewTopButtons.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        stackViewTopButtons.addTrackingArea(topButtonsTrackingArea!)
        boxMinimize.isHidden = true
        
    }
    
    
    override func viewWillAppear() {
        setframe()//todo // uncomment
    }
    
    @objc func setframe() {
        let screenList = NSScreen.screens
        for screen in screenList {  // create the corresponding windows
            self.view.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
            break;
        }
    }

    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == topButtonsTrackingArea{
            boxMinimize.isHidden = false
        }
    }
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == topButtonsTrackingArea{
            boxMinimize.isHidden = true
        }
    }
    @IBAction func btnMinimizeClicked(_ sender: Any) {
        btnAbortClicked(self)
    }
    
    @objc func showFocusSummaryView(){
        appdelegate!.checkSystemTimeAndShowWindow()
        if startTime == nil || shutOffTime == nil{
            return;
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich

        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
//
        }else{// not shutoff time//
            currentState = ._NOTHING_
            if mainWindowControllerObj?.window?.isVisible ?? false{
                self.view.window?.close()
                hideBlankWindowInSecondaryMonitor()
            }
            return;
        }
        allActivityTodaySummaryData = nil
        currentState = ._FOCUS_SUMMARY_
        allApiObject.getAllActivityDaySummary(completionHandler: {dic in
            DispatchQueue.main.async {
                if !(mainWindowControllerObj?.window!.isVisible)! {
                    mainWindowControllerObj?.showWindow(self)
                }
                showBlankWindowInSecondaryMonitor()
                
                addLog(text: "Showing Focus Summary")
                self.btnAbort.isHidden = true
                self.stackViewTopButtons.isHidden = true
                self.removeSubViews()
                self.containerView.addSubview(focusSummaryVcObj!.view)
                self.containerView.addConstraints(subView: focusSummaryVcObj!.view)
                focusSummaryVcObj!.reloadData()
            }
        })
        
    }
    
    var timerGiveOneMoreMinut:Timer?
    func giveOneMoreMinuteBeforeShutOffMac(){// state _FOCUS_SUMMARY_hi rahne denge taki kuch or bich mai naa aay
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        
        DispatchQueue.global().sync {
            self.timerGiveOneMoreMinut = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.showFocusSummaryViewAgain), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerGiveOneMoreMinut!), forMode: RunLoop.Mode.common)
        }
        var msg = "One minute timer ends in"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                msg = focusSummaryInfo.value(forKey: "oneMinuteTimerText") as? String ?? msg
            }
        }
        
        showSmallTimerWindow(durationSeconds: 60, msg: msg, isFocusBreak: false, currentTimerValue:0)
    }
    
    @objc func showFocusSummaryViewAgain(){
        DispatchQueue.main.async {
            addLog(text: "Showing Focus Summary again")
            
            self.showFocusSummaryView()
        }
    }
    
    func showLogQuantityView(){
        self.view.addSubview(logQuantityVcObj!.view)
        self.view.addConstraints(subView: logQuantityVcObj!.view)
    }
    func showTakeNotesView(){
        self.view.addSubview(getTakeActivityNotesVcObj().view)
        self.view.addConstraints(subView: getTakeActivityNotesVcObj().view)
    }
    
    
    func showSkipHabitView(){
        addLog(text: "show SkipHabit View")
        self.view.addSubview(getSkipHabitVcObject().view)
        self.view.addConstraints(subView: getSkipHabitVcObject().view)
        getSkipHabitVcObject().resetView()
    }
    func showWhySkipHabitView(){
        addLog(text: "show whySkipHabit View")
        self.view.addSubview(getWhySkipHabitVcObject().view)
        self.view.addConstraints(subView: getWhySkipHabitVcObject().view)
    }
    
    func showAskPostponeView(){
        addLog(text: "show AskPostpone View")
        self.view.addSubview(getAskPostponeVcObject().view)
        self.view.addConstraints(subView: getAskPostponeVcObject().view)
        getAskPostponeVcObject().resetView()
    }
    
    func abortOnboardingWork(){
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        if currentAction == ._INPROGRESS_{
            if timerViewcontrollerObj != nil {
                if timerViewcontrollerObj?.timer != nil {
                    timerViewcontrollerObj?.timer?.invalidate()
                    enableSystemSleep()
                    if timerViewcontrollerObj?.isVideoLodded ?? false{
                        if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                            if #available(macOS 12.0, *) {
                                if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
                                    timerViewcontrollerObj?.btnTabVideoClicked(self)
                                }
                                timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
                            } else {
                                // Fallback on earlier versions
                                timerViewcontrollerObj?.loadBlankUrl()
                            }
                        }
                    }
                }
            }
        }
        
        if currentState == ._ASK_APP_WORK_{
            if containerView.subviews.contains(getAskAppWorkVcObject().view){
                getAskAppWorkVcObject().btnContinue.isEnabled = false
                getAskAppWorkVcObject().loader.startAnimation(self)
                
                isHabitsDisabled = false
                
                var breaks_only = false
                if isHabitsDisabled{
                    breaks_only = true
                    UserDefaults.standard.set(true, forKey: kUserdefaultsIsHabitsDisabled)
                }else{
                    UserDefaults.standard.set(false, forKey: kUserdefaultsIsHabitsDisabled)
                }
                allApiObject.getHabitPacksInfo(breaks_only: breaks_only, completionHandler: {arrDic in
                    DispatchQueue.main.async {
                        getAskAppWorkVcObject().btnContinue.isEnabled = true
                        getAskAppWorkVcObject().loader.stopAnimation(self)
                    }
                    if arrDic != nil{
                        print(arrDic)
                        DispatchQueue.main.async {
                            self.abortOboardingHabitPack()
                            self.abortOboardingWorkTime()
                            
                        }
                    }
                })
                return;
            }else if containerView.subviews.contains(getSelectHabitPacksVcObject().view){
                abortOboardingHabitPack()
                
            }else if containerView.subviews.contains(getAskWorkTimeVcObject().view){
                
                
            }
            
            abortOboardingWorkTime()
            
        }else if currentState == ._BREATHING_{
            isFirstRun = true
            breathingFinishedUnlockMachine()
        }
    }
    
    func abortOboardingWorkTime(){
        UserDefaults.standard.set("05:15", forKey: kUserdefaultsStartupTimeFromOnboarding)
        UserDefaults.standard.set("20:30", forKey: kUserdefaultsShutOffTimeFromOnboarding)
        
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        
        isFirstRun = true
        breathingFinishedUnlockMachine()
    }
    func abortOboardingHabitPack(){
        if habitPacksData != nil{
            if habitPacksData!.count != 0{
                let pack = habitPacksData![0]
                let id = pack["id"] as? String ?? ""
                if !id.isEmpty{
                    UserDefaults.standard.set(id, forKey: kUserdefaultsPackIdSelected)
                }
            }
        }
    }
    func stopActivityCountDownTimer(){
        if currentAction == ._INPROGRESS_{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._SPECIAL_ACTIVITY_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        enableSystemSleep()
                        if timerViewcontrollerObj?.isVideoLodded ?? false{
                            if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                if #available(macOS 12.0, *) {
                                    if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
                                        timerViewcontrollerObj?.btnTabVideoClicked(self)
                                    }
                                    timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
                                } else {
                                    // Fallback on earlier versions
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                }
                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                    if smallCountDownWcObj?.window != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                            if getsmallCountDownVcObject().timer != nil {
                                getsmallCountDownVcObject().timer?.invalidate()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func btnAbortClicked(_ sender: Any) {
        addLog(text: "button Abort Clicked")
        if currentState == ._ASK_APP_WORK_ || currentState == ._BREATHING_{
            abortOnboardingWork()
            return;
        }
        
        
        lastCurrentState = currentState
        lastCurrentAction = currentAction
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        
        stopActivityCountDownTimer()
        
        if currentState == ._MORNING_HABIT_{
            
            refreshLastPostponeCount()
            
            if SettingsManagerObject.isEasySkipEnabled{
                
                if currentHabitPlaying != nil{
                    if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                        if smallCountDownWcObj?.window != nil{
                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                getSmallCountDownWindowObject().window?.close()
                            }
                        }
                    }
                }
                mainWindowControllerObj?.window?.setIsVisible(false)
                hideBlankWindowInSecondaryMonitor()
                
                showEasyPostponeWindow()
                stopActivityTimer()

                if currentHabitPlaying != nil{
                    closePupUpBlockIfVisible()
                }
                
            }else{
                stopActivityTimer()
                if activityPostponeCount == 0{
                    showAskPostponeView()
                }else{
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{                        
                        if SettingsManagerObject.isPasswordRequireInSkipMorning{
                            mainViewControllerObj?.showPasswordView()
                            enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                        }else{
                            showAskPostponeView()
                        }
                        
                    }else{
                        showAskPostponeView()
                    }
                    
                }
            }
            
        }else if currentState == ._EVENING_HABIT_{
            refreshLastPostponeCount()
            
            if SettingsManagerObject.isEasySkipEnabled{
                
                if currentHabitPlaying != nil{
                    if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                        if smallCountDownWcObj?.window != nil{
                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                getSmallCountDownWindowObject().window?.close()
                            }
                        }
                    }
                }
                mainWindowControllerObj?.window?.setIsVisible(false)
                hideBlankWindowInSecondaryMonitor()
                showEasyPostponeWindow()
                stopActivityTimer()

                if currentHabitPlaying != nil{
                    closePupUpBlockIfVisible()
                }
                
            }else{
                stopActivityTimer()
                if activityPostponeCount == 0{
                    showAskPostponeView()
                }else{
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                        if isHighPrioritySequenceGoing{
                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                showPasswordView()
                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                            }else{
                                showAskPostponeView()
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                showPasswordView()
                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                            }else{
                                showAskPostponeView()
                            }
                        }
                        
                        
                    }else{
                        showAskPostponeView()
                    }
                }
            }
        }else if currentState == ._ACTIVITY_{
            
            
            var lastSavedPostponeTime = Date()
            activityPostponeCount = 0
            var lastSavedPostponeCount = activityPostponeCount
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            
            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakActivityPostponeInfo) as? [String:Any]{
                
         
                if let postponeCount =  infoDic["postponeCount"] as? Int{
                    lastSavedPostponeCount = postponeCount
                }
                if let date =  infoDic["date"] as? Date{
                    lastSavedPostponeTime = date
                }
            }
            
                
            if lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
            }
                
            
            
            
            
            if SettingsManagerObject.isEasySkipEnabled{
                if currentAction == ._START_{
                    
                    if currentActivityPlaying != nil{
                        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                            if smallCountDownWcObj?.window != nil{
                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                    getSmallCountDownWindowObject().window?.close()
                                }
                            }
                        }
                    }
                    mainWindowControllerObj?.window?.setIsVisible(false)
                    hideBlankWindowInSecondaryMonitor()
                    showEasyPostponeWindow()
                    if currentActivityPlaying != nil{
//                        isAnyAllowedFocusModeActivityRunning = false
//                        currentActivityPlaying = nil// beacuse there is ono easy postpone cancel
                        closePupUpBlockIfVisible()
                        
//                        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
//                        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
//                        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
//                        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
//
//                        if smallCountDownWcObj != nil{// close timer window is easy postpone because there is no come back from easy postpone view
//                            if smallCountDownWcObj?.window != nil{
//                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
//                                    getSmallCountDownWindowObject().window!.close()
//                                }
//                            }
//                        }
                    }
                }else{
                    postponeBreakActivitiesFor(minutes: breakAfterMinutes)
                }
            }else{
                if currentAction == ._START_{// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
                    showAskPostponeView()
                }else{
                    showAskPostponeView()
                }
            }
            
        }else if currentState == ._FOCUS_SUMMARY_{
            showAskPostponeView()
        }else if currentState == ._SPECIAL_ACTIVITY_{
            specialActivityFinish()
        }
    }

    func processAborting(){
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if activityPostponeCount == 0{//it  means we did not ask for password when user clicked on please apare me button so need to ask now

                    if currentState == ._MORNING_HABIT_{
                        if SettingsManagerObject.isPasswordRequireInSkipMorning{
                            showPasswordView()
                        }else{
                            showAbortStartView()
                        }
                    }else if currentState == ._EVENING_HABIT_{
                        
                        if isHighPrioritySequenceGoing{
                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                showPasswordView()
                            }else{
                                showAbortStartView()
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                showPasswordView()
                            }else{
                                showAbortStartView()
                            }
                        }
                    }
                }else{
                    showAbortStartView()
                }
            }else{
                showAbortStartView()
            }
            
        }else{
            showAbortStartView()
        }
    }
    func showPasswordView(){
        self.view.addSubview(enterPasswordVcObj!.view)
        self.view.addConstraints(subView: enterPasswordVcObj!.view)
        enterPasswordVcObj?.parentVc = nil
        addLog(text: "Showing enter password view")
    }
    
    func showAbortStartView(){
        addLog(text: "showAbortStartView")
        removeSubViews()
        containerView.addSubview(abortingCountDownVcObj!.view)
        containerView.addConstraints(subView: abortingCountDownVcObj!.view)
        abortingCountDownVcObj?.startTimer()
        currentState = ._ABORT_
    }
    
    func abortCancel(){
        addLog(text: "abortCancel")
        
        if lastCurrentState == ._ACTIVITY_{
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                currentState = ._ACTIVITY_
                currentAction = ._START_
                thirdVcObj?.startBreakActivity()
                firstViewControllerObj?.isFirstTime = false
                
                containerView.addSubview(firstViewControllerObj!.view)
                containerView.addConstraints(subView: firstViewControllerObj!.view)
                firstViewControllerObj?.tblViewHabits.reloadData()
                break
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                
                timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: timerViewcontrollerObj?.currentDurationInSeconds ?? 0, name: timerViewcontrollerObj?.currentActicityTitle ?? "", url: timerViewcontrollerObj?.currentUrl)
                currentState = ._ACTIVITY_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                self.stackViewTopButtons.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._ACTIVITY_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                break
            case ._BRAIN_DUMP_:
                currentState = ._ACTIVITY_
                currentAction = ._BRAIN_DUMP_
                
                thirdVcObj?.startBreakActivity()
                showBreaksBrainDump()
                
                break
            }
        }else if lastCurrentState == ._MORNING_HABIT_{
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllMorningHabitsAbortCancel()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, url: arrFilteredMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrFilteredMorningHabits[currentHabitIndex].name!)
                currentState = ._MORNING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                self.stackViewTopButtons.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._MORNING_HABIT_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                currentState = ._MORNING_HABIT_
                mainViewControllerObj?.showVisualizeInstructionsVc()
                break
            case ._BRAIN_DUMP_:
                break
            }
            
        }else if lastCurrentState == ._EVENING_HABIT_{
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllEveningHabitsAbortCancel()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, url: arrFilteredEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrFilteredEveningHabits[currentHabitIndex].name!)
                currentState = ._EVENING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                self.stackViewTopButtons.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._EVENING_HABIT_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                currentState = ._EVENING_HABIT_
                mainViewControllerObj?.showVisualizeInstructionsVc()
                break
            case ._BRAIN_DUMP_:
                break
            }
            
        }else if lastCurrentState == ._SHUTOFFMAC_{
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            removeSubViews()
            shutOffMac()
        }else if lastCurrentState == ._FOCUS_SUMMARY_{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            self.btnAbort.isHidden = true
            self.stackViewTopButtons.isHidden = true
            self.removeSubViews()
            self.containerView.addSubview(focusSummaryVcObj!.view)
            self.containerView.addConstraints(subView: focusSummaryVcObj!.view)
            currentState = ._FOCUS_SUMMARY_
        }
    }
    
    
    func showAbortConfirmationView(){
        addLog(text: "showAbortConfirmationView")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        containerView.addSubview(abortingConfirmVcObj!.view)
        containerView.addConstraints(subView: abortingConfirmVcObj!.view)
        abortingConfirmVcObj!.resetData()
        currentState = ._ABORT_
        activityPostponeCount = 0
    }
    func showAbortStartSmallVc(isAnyHabitRemoved:Bool){
        addLog(text: "showAbortStartSmallVc")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        containerView.addSubview(abortingCantHandleVcObj!.view)
        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = true
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: isAnyHabitRemoved)
        currentState = ._ABORT_
    }
    func showAbortDisableMorningRoutineVc(){
        addLog(text: "showAbortDisableMorningRoutineVc")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        containerView.addSubview(abortingCantHandleVcObj!.view)
        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = false
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: false)
        currentState = ._ABORT_
    }
    func showAbortDoneView(){
        addLog(text: "showAbortDoneView")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        containerView.addSubview(abortDoneVcObj!.view)
        containerView.addConstraints(subView: abortDoneVcObj!.view)
        abortDoneVcObj?.startTimer()
        currentState = ._ABORT_
    }
    func disableApp(){
        addLog(text: "App Deactivated by user (Aborted)")
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsAppEnabled)
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastAppAbortedDate)
        appdelegate?.quitAndRestartApp()
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    func removeSubViews(){
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        let views = self.view.subviews
        if views.count != 1{
            for subview in views {
                if subview != boxContainer{
                    subview.removeFromSuperview()
                }
            }
        }
        
    }
    
    func shutOffMac(){
        isHabitAlreadyShowed = false
        if currentState == ._SHUTOFFMAC_{
            return;
        }
        addLog(text: "Showing Shut Off screen.")
        btnAbort.isHidden = true//changed no abort button in shut off view
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        containerView.addSubview(shutOffTimeVcObj!.view)
        containerView.addConstraints(subView: shutOffTimeVcObj!.view)
        currentState = ._SHUTOFFMAC_
        if self.breakTimer != nil{
            self.breakTimer?.invalidate()
            self.breakTimer = nil
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showFirstTimeVc(){
        addLog(text: "Showing first time welcome activity.")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        firstViewControllerObj?.isFirstTime = true//ik bar object bna or dusri line mai true hua debug mode mai qki debug mode mai sare global variables ya obj call krne k baad initialize hote hai
        firstViewControllerObj?.isFirstTime = true
//        firstViewControllerObj?.isGetKookyButtonVisible = false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        currentState = ._BREATHING_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showAskAppWorkVc(){
        addLog(text: "Showing Ask App Work view.")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()

        containerView.addSubview(getAskAppWorkVcObject().view)
        containerView.addConstraints(subView: getAskAppWorkVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    func showSelectHabitPacksVc(){
        addLog(text: "Showing Select Habit Packs view.")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()

        containerView.addSubview(getSelectHabitPacksVcObject().view)
        containerView.addConstraints(subView: getSelectHabitPacksVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showAskWorkTimeVc(){
        addLog(text: "Showing Ask Work Time view.")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()

        containerView.addSubview(getAskWorkTimeVcObject().view)
        containerView.addConstraints(subView: getAskWorkTimeVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    
    
    
//    func showAskHabitSkipEasinessVc(){
//        addLog(text: "show Ask Habit Skip Easiness Vc.")
//        btnAbort.isHidden = true
//        self.stackViewTopButtons.isHidden = true
//        removeSubViews()
//
//        containerView.addSubview(getHabitSkipEasinessVcObject().view)
//        containerView.addConstraints(subView: getHabitSkipEasinessVcObject().view)
//        currentState = ._ASK_APP_WORK_
//        currentAction = ._START_
//        NSApplication.shared.activate(ignoringOtherApps: true)
//    }
    
//    func showOnboardingBlockedUrlsVc(){
//        addLog(text: "show Onboarding Blocked Urls.")
//        btnAbort.isHidden = true
//        self.stackViewTopButtons.isHidden = true
//        removeSubViews()
//        containerView.addSubview(getOnboardingBlockedUrlsVcObject().view)
//        containerView.addConstraints(subView: getOnboardingBlockedUrlsVcObject().view)
//        currentState = ._ASK_APP_WORK_
//        currentAction = ._START_
//        NSApplication.shared.activate(ignoringOtherApps: true)
//    }
    
    
    func showVisualizeInstructionsVc(){
        addLog(text: "show Visualize Instructions Vc.")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        currentAction = ._VISUALIZE_
        containerView.addSubview(getvisualizeInstructionsObject().view)
        containerView.addConstraints(subView: getvisualizeInstructionsObject().view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showBreaksBrainDump(){
        addLog(text: "show Breaks Brain Dump.")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        currentAction = ._BRAIN_DUMP_
        containerView.addSubview(getBreaksBrainDumpVcObject().view)
        containerView.addConstraints(subView: getBreaksBrainDumpVcObject().view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    
    func showAllEveningHabits(){
        addLog(text: "func showAllEveningHabits:- Initiate and run Evening Habits.")
        
        
        if easyPostponeWcObj != nil{
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
        }
        
        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
            currentState = ._EVENING_HABIT_
            showVisualizeInstructionsVc()
            addLog(text: "func showAllEveningHabits:- current action is visualize:- return")
            return;
        }
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitID)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        
        if isHighPrioritySequenceGoing{
            if !arrFilteredEveningHabits[0].isPriorityHigh{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
                isLastActivityStoppedInRunningState = false
            }
        }
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredEveningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllEveningHabits:- Activity Postpone In Running State:- start direct \(arrFilteredEveningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            
            currentHabitIndex = 0
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastSavedActivityId == arrFilteredEveningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllEveningHabits:- app terminate In Running State:- start direct \(arrFilteredEveningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            currentHabitIndex = 0
            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
        }else{
            addLog(text:"func showAllEveningHabits:- show All Evening Habits")
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            isLastActivityStoppedInRunningState = false
            isPromptToRememberHabitShowedInLastHabit = false
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            removeSubViews()
            
            if isHighPrioritySequenceGoing{
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].isPriorityHigh{
                        currentHabitIndex = i - 1
                        break;
                    }
                }
            }else{
                currentHabitIndex = -1
            }
            
            
            currentState = ._EVENING_HABIT_
            currentAction = ._START_
            firstViewControllerObj?.isFirstTime = false
    //        firstViewControllerObj?.isGetKookyButtonVisible = true
            containerView.addSubview(firstViewControllerObj!.view)
            containerView.addConstraints(subView: firstViewControllerObj!.view)
            NSApplication.shared.activate(ignoringOtherApps: true)
            playStartMorningEveningRoutineSound()
        }
    }
    
    func showAllEveningHabitsAbortCancel(){
        addLog(text: "Abort Cancel:-Initiate and run Evening Habits.")
        isPromptToRememberHabitShowedInLastHabit = false
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        currentState = ._EVENING_HABIT_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
//        firstViewControllerObj?.isGetKookyButtonVisible = false// don't need to do any thing because its important to show kooky timer and once kooky timer begines we make it false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showAllMorningHabits(){
        addLog(text: "func showAllMorningHabits:- Showing morning habits.")

        
        if easyPostponeWcObj != nil{
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
        }
        
        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
            currentState = ._MORNING_HABIT_
            showVisualizeInstructionsVc()
            addLog(text: "func showAllMorningHabits:- current action is visualize:- return")
            return;
        }
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitID)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredMorningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllMorningHabits:- Activity Postpone In Running State:- start direct \(arrFilteredMorningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            
            currentHabitIndex = 0
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrFilteredMorningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllMorningHabits:- app terminate In Running State:- start direct \(arrFilteredMorningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            currentHabitIndex = 0
            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
        }else{
            addLog(text:"func showAllMorningHabits:- show All Morning Habits")
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            isLastActivityStoppedInRunningState = false
            isPromptToRememberHabitShowedInLastHabit = false
            lastShownRandomChoiceDic = [String:activityChoice]()
            btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            removeSubViews()
            currentState = ._MORNING_HABIT_
            currentAction = ._START_
            firstViewControllerObj?.isFirstTime = false
            //        firstViewControllerObj?.isGetKookyButtonVisible = true
            containerView.addSubview(firstViewControllerObj!.view)
            containerView.addConstraints(subView: firstViewControllerObj!.view)
            NSApplication.shared.activate(ignoringOtherApps: true)
            playStartMorningEveningRoutineSound()
        }
    }
    func showAllMorningHabitsAbortCancel(){
        addLog(text: "Abort Cancel Showing morning habits.")
        isPromptToRememberHabitShowedInLastHabit = false
        lastShownRandomChoiceDic = [String:activityChoice]()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        currentState = ._MORNING_HABIT_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
//        firstViewControllerObj?.isGetKookyButtonVisible = false// don't need to do any thing because its important to show kooky timer and once kooky timer begines we make it false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func startFirstMorningHabit() {
        addLog(text:"current startFirstMorningHabit called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        currentHabitIndex = 0
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-morning-routine", metadata: ["routine-type":"morning_routine"])
    }
    
    func startFirstEveningHabit() {
        addLog(text:"current startFirstEveningHabit called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        
        
        if isHighPrioritySequenceGoing{
            for i in 0..<arrFilteredEveningHabits.count{
                if arrFilteredEveningHabits[i].isPriorityHigh{
                    currentHabitIndex = i
                    break;
                }
            }
        }else{
            currentHabitIndex = 0
        }
        
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-evening-routine", metadata: ["routine-type":"evening_routine"])
    }
    func startBreathing() {
        addLog(text:"current startBreathing called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startBreathing()
        currentState = ._BREATHING_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-first-routine", metadata: ["routine-type":"first_routine"])
    }
    
    func breathingOver(isSKipped:Bool) {
        addLog(text:"current breathing Habit Over called")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.breathingFinished(isSKipped: isSKipped)
        currentState = ._BREATHING_
        currentAction = ._END_
        allApiObject.capturePosthog(event: "complete-first-routine", metadata: ["routine-type":"first_routine"])
    }
    func morningHabitOver() {
        addLog(text:"current morning Habit Over called")
        mainViewControllerObj?.stopActivityTimer()
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
        }
        //        activityAllowedFocusApps.removeAll()
        //        activityAllowedFocusUrls.removeAll()
        //                activityAllowedFocusMode = nil
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        
        if toolBoxWcObj != nil{
            if toolBoxWcObj!.window!.isVisible{
                toolBoxWcObj?.window?.close()
            }
        }
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()

        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.morningHabitFinished(index: currentHabitIndex)
        currentState = ._MORNING_HABIT_
        currentAction = ._END_
        if activityPostponeCount > 3{
            activityPostponeCount = 3//I complete a habit after postponing, it should go back to a 15 second postpone the next time
            savePostpneCount(state: ._MORNING_HABIT_)
        }
    }
    
    func startDirectIncompleteMorningHabitAtIndex(index:Int, isLastActivitySkipped:Bool) {
        addLog(text:"func:- startDirectIncompleteMorningHabitAtIndex")
        currentState = ._MORNING_HABIT_// pahle isiliye kiya qki load graph mai check lagaya hua h state ka 
        currentAction = ._END_
        //        activityAllowedFocusApps.removeAll()
        //        activityAllowedFocusUrls.removeAll()
        //                activityAllowedFocusMode = nil
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        
        if toolBoxWcObj != nil{
            if toolBoxWcObj!.window!.isVisible{
                toolBoxWcObj?.window?.close()
            }
        }
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        
        if easyPostponeWcObj != nil{
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
        }
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredMorningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- Activity Postpone In Running State:- start direct \(arrFilteredMorningHabits[index].name ?? "") in running state")
            
            currentHabitIndex = index
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
            
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrFilteredMorningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredMorningHabits[index].name ?? "") in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- morningHabitFinishedAndStartIncompleteNew")
            isLastActivityStoppedInRunningState = false
            
            if index == 0{
                showAllMorningHabits()
            }else{
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentHabitIndex = index-1
                thirdVcObj!.morningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
            }
            
        }
        
    }

    func showThirdVc(){
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
    }
    func eveningHabitOver() {
        addLog(text:"current evening Habit Over called")
        mainViewControllerObj?.stopActivityTimer()
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
        }
        //        activityAllowedFocusApps.removeAll()
        //        activityAllowedFocusUrls.removeAll()
        //                activityAllowedFocusMode = nil
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        if toolBoxWcObj != nil{
            if toolBoxWcObj!.window!.isVisible{
                toolBoxWcObj?.window?.close()
            }
        }
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        //        if currentHabitIndex < arrFilteredEveningHabits.count-1 {
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.eveningHabitFinished(index: currentHabitIndex)
        currentState = ._EVENING_HABIT_
        currentAction = ._END_

        if activityPostponeCount > 3{
            activityPostponeCount = 3//I complete a habit after postponing, it should go back to a 15 second postpone the next time
            savePostpneCount(state: ._EVENING_HABIT_)
        }
    }
    func startDirectIncompleteEveningHabitAtIndex(index:Int, isLastActivitySkipped:Bool) {
        addLog(text:"func startDirectIncompleteEveningHabitAtIndex")
        currentState = ._EVENING_HABIT_// pahle isiliye kiya qki load graph mai check lagaya hua h state ka
        currentAction = ._END_
        //        activityAllowedFocusApps.removeAll()
        //        activityAllowedFocusUrls.removeAll()
        //                activityAllowedFocusMode = nil
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        
        if toolBoxWcObj != nil{
            if toolBoxWcObj!.window!.isVisible{
                toolBoxWcObj?.window?.close()
            }
        }
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        
        if easyPostponeWcObj != nil{
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
        }
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        
        
        if isHighPrioritySequenceGoing{
            if !arrFilteredEveningHabits[index].isPriorityHigh{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
                isLastActivityStoppedInRunningState = false
            }
        }
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredEveningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- Activity Postpone In Running State:- start direct\(arrFilteredEveningHabits[index].name ?? "")in running state")
            
            currentHabitIndex = index
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastSavedActivityId == arrFilteredEveningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredEveningHabits[index].name ?? "") in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- eveningHabitFinishedAndStartIncompleteNew")
            isLastActivityStoppedInRunningState = false
            
            if index == 0{
                showAllEveningHabits()
            }else{
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentHabitIndex = index-1
                thirdVcObj!.eveningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
            }
        }
    }
    func eveningHabitFinishShowShutOff(){
        addLog(text: "evening habit Finished")
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        shutOffMac()
        
        var eveningRoutineDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsEveningRoutineDoneCount) as? Int ?? 0
        eveningRoutineDoneCount += 1
        UserDefaults.standard.set(eveningRoutineDoneCount, forKey: kUserdefaultsEveningRoutineDoneCount)
    }
    
    func specialActivityFinish(){
        addLog(text: "special Activity Finished")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        lblMessage.isHidden = true
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        currentState = ._NOTHING_
    }
    
    func activityOver() {
        addLog(text:"current activityOver called")
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
        }
        //        activityAllowedFocusApps.removeAll()
        //        activityAllowedFocusUrls.removeAll()
        //                activityAllowedFocusMode = nil
        isAnyAllowedFocusModeActivityRunning = false
        currentActivityPlaying = nil
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.activityFinished(index: currentActivityIndex)
        currentState = ._ACTIVITY_
        currentAction = ._END_
    }
    func specialActivityOver() {
        addLog(text:"current specialActivity Over called")
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
        }

        isAnyAllowedFocusModeActivityRunning = false
        currentActivityPlaying = nil
        currentHabitPlaying = nil
        
        if toolBoxWcObj != nil{
            if toolBoxWcObj!.window!.isVisible{
                toolBoxWcObj?.window?.close()
            }
        }
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.specialActivityFinished()
        currentState = ._SPECIAL_ACTIVITY_
        currentAction = ._END_
    }
    func changeMorningHabit() {
        addLog(text:"current change Morning Habit called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        currentHabitIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
//        let videoUrl = getRandomVideoUrl(activityId:arrFilteredMorningHabits[currentHabitIndex].id, urlsArray: arrFilteredMorningHabits[currentHabitIndex].urlsArray)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    
    
    
    func changeEveningHabit() {
        addLog(text:"current change Evening Habit called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        
        currentHabitIndex += 1
        if isHighPrioritySequenceGoing{
            while !arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
                currentHabitIndex = currentHabitIndex + 1
            }
            
        }
     
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    func startSpecialActivity(duration:Int,habit:habit?, activity:breakActivity?){
//        allApiObject.capturePosthog(event: "start-break-activity", metadata: ["routine-type":"break_activity"])
//        addLog(text:"start Current Activity called")
        
        if easyPostponeWcObj != nil{
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
        }
        if isFocusModeOnOrPaused(){
            addLog(text: "Special Activity start:- Focus Mode Finished")
            appdelegate?.focusModeFinished(isSilent: true)
        
        }
        mainWindowControllerObj?.showWindow(self)
        showBlankWindowInSecondaryMonitor()

        currentState = ._SPECIAL_ACTIVITY_
        currentAction = ._INPROGRESS_
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        
        var currentChoice:activityChoice?
        if activity != nil{
            if activity!.isRandomChoice{
                if let randomChoice = activity!.choices.randomElement(){
                    currentChoice = randomChoice
                }
            }
        }
        
        timerViewcontrollerObj?.startSpecialActivity(durationSeconds: duration, currentHabit: habit, currentActivity: activity, currentChoice: currentChoice)
    }
    func startCurrentActivity() {
        allApiObject.capturePosthog(event: "start-break-activity", metadata: ["routine-type":"break_activity"])
        addLog(text:"start Current Activity called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        if isMandatoryActivityGoing{
            let currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
            
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
            }else{//random choice
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }
            }
            
            
        }else{
            let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
            }else{//random choice
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }
            }
            
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    
    
    func changeActivity() {
        addLog(text:"current change Activity called")
        btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        removeSubViews()
        //  isBreakActivitiesGoing = true
        //        currentActivityIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                let lastIndex = currentActivityIndex
                currentActivityIndex += 1
                if currentActivityIndex > arrActivitiesIncludeInEveryBreak.count - 1{
                    currentActivityIndex = lastIndex// phle hi current index le rakhki thi ..is condition k liye
                    isMandatoryActivityGoing = false//
                    
                    let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                    
                    if !currentActivity.isRandomChoice{
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
                    }else{
                        if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }else if let randomChoice = currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }
                    }
                    
                }else{
                    let currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
                    
                    if !currentActivity.isRandomChoice{
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
                    }else{
                        if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }else if let randomChoice = currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }
                    }
                }
            }else{
                let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                
                if !currentActivity.isRandomChoice{
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
                }else{
                    if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                    }else if let randomChoice = currentActivity.choices.randomElement(){
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                    }
                }
            }
        }else{
            currentActivityIndex += 1
            let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
            
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
            }else{
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }
            }
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    
    func habitsFinishedUnlockMachine() {
        addLog(text: "morning habit Finished")
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        lblMessage.isHidden = false
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
        }
        currentHabitIndex = -1
       
        var morningRoutineDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsMorningRoutineDoneCount) as? Int ?? 0
        morningRoutineDoneCount += 1
        UserDefaults.standard.set(morningRoutineDoneCount, forKey: kUserdefaultsMorningRoutineDoneCount)
        
        
        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
        unfocusedTime = 0
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                appdelegate?.showMorningPomodoroModeView()
            }
        }
        currentState = ._NOTHING_
    }
    
    @objc func unlockMachine() {
        addLog(text:"current unlockMachine called")

        lblMessage.isHidden = true
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        activityPostponeCount = 0
        activitySkipCount = 0
        if isFirstRun{//welcome routine k baad set krenge (when first time)
//            appdelegate!.setBackgroundThreadTimer()
            isFirstRun = false
//            appdelegate?.menuItem_Preferences()
            if appdelegate!.user == nil{
//                appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
//                appdelegate!.login()
                showAskLoginWindow()
            }
        }else{
            setActivityTimer()
        }
    }
    
    func stopActivityTimer(){
        if breakTimer != nil{
            breakTimer?.invalidate()
            breakTimer = nil
            addLog(text: "stopActivityTimer")
        }
    }
    var breakTimer: Timer?
    var postponeTimer: Timer?
    var postponeNotificationTimer: Timer?
    
    func setActivityTimer(){
        addLog(text: "Break Activity Timer reset Done.")
        if arrAllbreakActivities.count != 0 {
            DispatchQueue.global().sync {
                print("breakAfterMinutesxxxx")
                if self.breakTimer != nil{
                    self.breakTimer?.invalidate()
                    self.breakTimer = nil
                }
                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(breakAfterMinutes*60), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)//todo breakAfterMinutes*60 kro//

                RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
            }
        }
    }
    var isBreakActivityPostponeInsideAllowedHabit = false// using this beacuse we dont want reset activity timer again (in resuming habit) if user has postponed activity inside allow app habit 
    func postponeBreakActivitiesFor(minutes:Int){
        addLog(text: "postpone Break Activities, Timer reset Done:- \(minutes) minutes")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
        removeSubViews()
        currentState = ._NOTHING_
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        if arrAllbreakActivities.count != 0 {
            DispatchQueue.global().sync {//async {
                print("breakAfterMinutesxxxx")
                if self.breakTimer != nil{
                    self.breakTimer?.invalidate()
                    self.breakTimer = nil
                }
                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)//todo  minutes*60 kro
//                RunLoop.current.add(self.breakTimer!, forMode: RunLoop.Mode.common)
//                RunLoop.current.run()
            RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
            }
        }
        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
            isBreakActivityPostponeInsideAllowedHabit = true
            DispatchQueue.global().async {
                sleep(5)
                self.isBreakActivityPostponeInsideAllowedHabit = false
            }
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            appdelegate!.backgroundThread()
        }
        
    }
    
    func savePostpneCount(state:CURRENTSTATE){
        if state == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                let infoDic:[String:Any] = ["sequenceId":arrFilteredMorningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":Date()]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
                print(infoDic)
            }
        }else if state == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                
                var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                
                let curreentDate = Date()
                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate

                }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time

                }
                
                let infoDic:[String:Any] = ["sequenceId":arrFilteredEveningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":startDate]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
                print(infoDic)
            }
        }
    }
    func refreshLastPostponeCount(){
        var lastSavedPostponeTime = Date()
        activityPostponeCount = 0
        var lastSavedPostponeCount = activityPostponeCount
        var lastSavedSequenceId = ""
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequencePostponeInfo) as? [String:Any]{
            
            if let id =  infoDic["sequenceId"] as? String{
                lastSavedSequenceId = id
            }
            if let postponeCount =  infoDic["postponeCount"] as? Int{
                lastSavedPostponeCount = postponeCount
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedPostponeTime = date
            }
        }
        if currentState == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                if lastSavedSequenceId == arrFilteredEveningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
                }
            }
        }
    }
    func postponeMorningHabitFor(minutes:Int, secondsToPostpone:Int?){
        var seconds = 0
        if secondsToPostpone != nil{
            seconds = secondsToPostpone!
            if seconds == 0 && minutes != 0{
                seconds = minutes*60
            }
        }else{
            seconds = minutes*60
        }
        addLog(text: "postpone morning habits, Timer reset Done:- \(seconds) seconds")
        savePostpneCount(state: ._MORNING_HABIT_)
        
        if currentAction == ._INPROGRESS_{
            isLastActivityStoppedInRunningState = true
            lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
        }else{
            isLastActivityStoppedInRunningState = false
            lastActivityRunningId = ""
        }
        
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        currentState = ._POSTPON_MORNING_HABIT_
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                    if currentHabitPlaying != nil{
                        getSmallCountDownWindowObject().window!.close()
                    }
                }
            }
        }
        
        if arrFilteredMorningHabits.count != 0 {
            DispatchQueue.global().sync{//async {
                if self.postponeTimer != nil{
                    self.postponeTimer?.invalidate()
                    self.postponeTimer = nil
                }
                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.resumeMorningHabit), userInfo: nil, repeats: false)//todo  seconds
                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
                
                if seconds > 120{
                    setPostponeNotificationTimer(duration: ((seconds) - 120))
                }
            }
        }
    }
    func postponeEveningHabitFor(minutes:Int, secondsToPostpone:Int?){
        var seconds = 0
        if secondsToPostpone != nil{
            seconds = secondsToPostpone!
            if seconds == 0 && minutes != 0{
                seconds = minutes*60
            }
        }else{
            seconds = minutes*60
        }
        
        
        addLog(text: "postpone evening habits, Timer reset Done:- \(seconds) seconds")
        
        savePostpneCount(state: ._EVENING_HABIT_)
        eveningRoutineLastPostponeTime = Date()
        if currentAction == ._INPROGRESS_{
            isLastActivityStoppedInRunningState = true
            lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
        }else{
            isLastActivityStoppedInRunningState = false
            lastActivityRunningId = ""
        }
        
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        currentState = ._POSTPON_EVENING_HABIT_
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                    if currentHabitPlaying != nil{
                        getSmallCountDownWindowObject().window!.close()
                    }
                }
            }
        }
        if arrFilteredEveningHabits.count != 0 {
            DispatchQueue.global().sync{//async {
                if self.postponeTimer != nil{
                    self.postponeTimer?.invalidate()
                    self.postponeTimer = nil
                }
                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.resumeEveningHabit), userInfo: nil, repeats: false)//todo  seconds
                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
                
                if seconds > 120{
                    setPostponeNotificationTimer(duration: ((seconds) - 120))
                }
            }
        }
    }
    
    func postponeFocusSummaryFor(minutes:Int){
        addLog(text: "postpone Focus Summary Done:- \(minutes) minutes")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        currentState = ._POSTPON_FOCUS_SUMMARY_
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
     
            DispatchQueue.global().sync{//async {
                if self.postponeTimer != nil{
                    self.postponeTimer?.invalidate()
                    self.postponeTimer = nil
                }
                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.resumeFocusSummary), userInfo: nil, repeats: false)//todo  minutes*60 kroTimeInterval(minutes*60)
                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
                
                if minutes > 2{
                    setPostponeNotificationTimer(duration: ((minutes*60) - 120))
                }
            }
    }
    
    func setPostponeNotificationTimer(duration:Int){
        
        if self.postponeNotificationTimer != nil{
            self.postponeNotificationTimer?.invalidate()
            self.postponeNotificationTimer = nil
        }
        self.postponeNotificationTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.showPostponeEndNotification), userInfo: nil, repeats: false)
        RunLoop.main.add((postponeNotificationTimer!), forMode: RunLoop.Mode.common)
    }
    
    @objc func showPostponeEndNotification(){
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_MORNING_HABIT_{
            var msg = "Habit resumes in"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                msg = common.value(forKey: "postponeEndsText") as? String ?? msg
            }
            
            showSmallTimerWindow(durationSeconds: 120, msg: msg, isFocusBreak: true, currentTimerValue: 0)
        }
    }
    @objc func resumeMorningHabit(){// func name "backgrounThread" will do work for showing morning routing again we just need to false this (currentState) variable
        addLog(text: "Morning habits postpone finished")
        if currentState == ._POSTPON_MORNING_HABIT_{
            currentState = ._NOTHING_
        }
    }
    
    @objc func resumeEveningHabit(){// func name "backgrounThread" will do work for showing evening routing again we just need to false this (currentState) variable
        addLog(text: "Evening habits postpone finished")
        if currentState == ._POSTPON_EVENING_HABIT_{
            currentState = ._NOTHING_
        }
    }
    
    @objc func resumeFocusSummary(){// func name "backgrounThread" will do work for showing morning routing again we just need to false this (isMorningRoutinePostpone) variable
        addLog(text: "Focus Summary postpone finished")
        currentState = ._NOTHING_
//        showFocusSummaryView()// nahi hai jarurat iski
    }
    func activityFinishedUnlockMachine() {
        addLog(text: "Break Activities Finished")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        activityPostponeCount = 0
        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
        print(infoDic)
        //        lblMessage.isHidden = false
        //        isBreakActivitiesGoing = false
        currentActivityIndex = -1
        unlockMachine()
        currentState = ._NOTHING_
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            if !notes.isEmpty{
                showBrainDumpWindow()
            }
        }
        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            addLog(text: "Break Activity Finished:- Try resume Habit Routine")
            appdelegate!.backgroundThread()
        }
    }
    func breathingFinishedUnlockMachine(){
        addLog(text: "breathing Finished")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        lblMessage.isHidden = true
//        if let common = configjson.value(forKey: "common") as? NSDictionary{
//            lblMessage.stringValue = common.value(forKey: "letsCreatAccountText") as? String ?? lblMessage.stringValue
//        }
        //        isBreathingGoing = false
//        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
        unlockMachine()
        currentState = ._NOTHING_
    }

    // prevent user sleep on ka alog sahi krdena
    @objc func timeToStartBreakActivities() {
        DispatchQueue.main.async {
            addLog(text: "Initiating Break Activities")
            self.breakTimer?.invalidate()
            self.breakTimer = nil
            
            if arrAllbreakActivities.count == 0 {
                self.setActivityTimer()
                addLog(text: "Break Activities count is 0 :- Break Activities cancelled.")
                return;
            }
            if currentState == ._SPECIAL_ACTIVITY_{
                self.setActivityTimer()
                addLog(text: "Special activity is running :- Break Activities cancelled.")
                return;
            }
            
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            checkLogFileRotation()

            let isFocusModeOnOrPaused = isFocusModeOnOrPaused()
            if isFocusModeOnOrPaused && isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
                self.setActivityTimer()
                addLog(text: "Pomodoro mode is On: Break Activities cancelled.")
                return
            }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
                self.setActivityTimer()
                addLog(text: "Super Pomodoro mode is On: Break Activities cancelled.")
                return
            }else if isFocusModeOnOrPaused && isSkipBreakActivityDuringFocus{
                self.setActivityTimer()
                addLog(text: "Focus mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
                return
            }
            
            if appdelegate!.isUserOnMeeting{
                addLog(text: "isUserOnMeeting True: Break Activities cancelled.")
                self.setActivityTimer()
                return;
            }
            
            if currentState == ._MORNING_HABIT_{// ⚠️ do not change current state inside this block
                // new work // 23/12/22
                if currentHabitPlaying != nil && !(mainWindowControllerObj?.window?.isVisible ?? false) && currentAction == ._INPROGRESS_{//it means background morning habit and now break activity is allowed in allowed app morning habit // 23/12/22
                    addLog(text: "Morning habit showing, Break Activities allowed in allowed app morning habit.")
                    
                    // pause  morning activity and start break activity
                    // will not change current state here beacuse we do not want to execute background thread during warning but need to handle when pc goint to sleep during warning
                    mainWindowControllerObj?.window?.setIsVisible(false)
                    hideBlankWindowInSecondaryMonitor()
                    isLastActivityStoppedInRunningState = true
                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                    isBreakActivityExecuteFromMorningHabit = true
                    
                    if timerViewcontrollerObj != nil {
                        if timerViewcontrollerObj?.timer != nil {
                            timerViewcontrollerObj?.timer?.invalidate()
                            enableSystemSleep()
                            if timerViewcontrollerObj?.isVideoLodded ?? false{
                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                    
                    if currentHabitPlaying != nil{
                        isAnyAllowedFocusModeActivityRunning = false
                        currentHabitPlaying = nil
                        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                        
                        closePupUpBlockIfVisible()
                        
                        if smallCountDownWcObj != nil{//
                            if smallCountDownWcObj?.window != nil{
                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                    smallCountDownVcObj?.closeTimerBox()
                                }
                            }
                        }
                    }
                    // self.timerAllowAppForActivity?.invalidate() ye invalid nahi hua //
                    
                    
                    
                   // //////////////
                }else{
                    addLog(text: "Morning habit showing, Break Activities cancelled.")
                    return;
                }
                
            }
            
            
            if currentState == ._EVENING_HABIT_{// ⚠️ do not change current state inside this block
               
                // new work // 23/12/22
                if currentHabitPlaying != nil && !(mainWindowControllerObj?.window?.isVisible ?? false) && currentAction == ._INPROGRESS_{//it means background evening habit and now break activity is allowed in allowed app morning habit // 23/12/22
                    addLog(text: "Evening habit showing, Break Activities allowed in allowed app Evening habit.")
                    
                    // pause  evening activity and start break activity
                    // will not change current state here beacuse we do not want to execute background thread during warning but need to handle when pc goint to sleep during warning
                    mainWindowControllerObj?.window?.setIsVisible(false)
                    hideBlankWindowInSecondaryMonitor()
                    isLastActivityStoppedInRunningState = true
                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                    isBreakActivityExecuteFromEveningHabit = true
                    
                    if timerViewcontrollerObj != nil {
                        if timerViewcontrollerObj?.timer != nil {
                            timerViewcontrollerObj?.timer?.invalidate()
                            enableSystemSleep()
                            if timerViewcontrollerObj?.isVideoLodded ?? false{
                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                    
                    if currentHabitPlaying != nil{
                        isAnyAllowedFocusModeActivityRunning = false
                        currentHabitPlaying = nil
                        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                        closePupUpBlockIfVisible()
                        
                        if smallCountDownWcObj != nil{//
                            if smallCountDownWcObj?.window != nil{
                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                    smallCountDownVcObj?.closeTimerBox()
                                }
                            }
                        }
                    }
                    
                    
                   // //////////////
                }else{
                    addLog(text: "Evening habit showing, Break Activities cancelled.")
                    return;
                }
                
            }
            
            
            
            
            if currentState == ._SHUTOFFMAC_{
                addLog(text: "App is in shutoff state, Break Activities cancelled.")
                return;
            }
            if currentState == ._ABORT_{
                addLog(text: "App state is abort, Break Activities cancelled.")
                return;
            }
            
            if isShutOffTimeGoing() && currentState != ._EVENING_HABIT_{
                addLog(text: "not working hours, Break Activities cancelled.")
                return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary or evening routine k time per bhi rreturn ho jayga
            }
            
            self.reFillBreakActivitiesArray()
            if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
                self.setActivityTimer()//possible nahi hai
                return;
            }
            self.removeSubViews()
            
            showBreakWarningWindow()
            currentState = ._ACTIVITY_
        }
    }
        
    func reFillBreakActivitiesArray(){
        isAnyMandatoryActivityIncluded = false
        arrActivitiesExcludeInEveryBreak.removeAll()
        arrActivitiesIncludeInEveryBreak.removeAll()
        isMandatoryActivityGoing = false
        
        for activity in arrAllbreakActivities{
            if SettingsManagerObject.isOfficeModeEnabled{
                if !activity.isOfficeFriendly{
                    continue;
                }
            }
            if activity.IncludeInEveryBreak{
                isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory arra than normal array
                arrActivitiesIncludeInEveryBreak.append(activity)
            }else{
                arrActivitiesExcludeInEveryBreak.append(activity)
            }
        }
        //                checking if  Office Mode is on and if there is not any activity office friendly than turn off office mode
        if SettingsManagerObject.isOfficeModeEnabled{
            if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
                addLog(text: "SettingsManagerObject.isOfficeModeEnabled false becuse no office friendly activity found.")
                SettingsManagerObject.isOfficeModeEnabled = false
                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsOfficeModeEnabled)
                
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
                
                
                for activity in arrAllbreakActivities{
                    if activity.IncludeInEveryBreak{
                        isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory array than normal array
                        arrActivitiesIncludeInEveryBreak.append(activity)
                    }else{
                        arrActivitiesExcludeInEveryBreak.append(activity)
                    }
                }
                
            }
        }
        arrFinalBreakActivities.removeAll()//Tell user what break activities are coming up#479
        if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
            //addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
            //self.setActivityTimer()//possible nahi hai
            return;
        }
        
        
        if isAnyMandatoryActivityIncluded{
            isMandatoryActivityGoing = true
            currentActivityIndex = 0
            for activity in arrActivitiesIncludeInEveryBreak{
                arrFinalBreakActivities.append(breakActivityFilter(activity: activity, randomChoice: nil))
            }
            
            if arrActivitiesExcludeInEveryBreak.count != 0{
                randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
                arrFinalBreakActivities.append(breakActivityFilter(activity: arrActivitiesExcludeInEveryBreak[randomActivityIndex], randomChoice: nil))
            }
        }else{
            currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
            randomActivityIndex = currentActivityIndex
            arrFinalBreakActivities.append(breakActivityFilter(activity: arrActivitiesExcludeInEveryBreak[currentActivityIndex], randomChoice: nil))
        }
        //
        
        
        for i in 0..<arrFinalBreakActivities.count{//
            let filterActivity = arrFinalBreakActivities[i]
            if let currentActivity = filterActivity.activity{
                if currentActivity.isRandomChoice{
                    var currentActivityChoice = currentActivity.choices.randomElement()
                    
                    if currentActivity.choices.count != 1{
                        if let lastChoice = lastShownRandomChoiceDic[currentActivity.id]{
                            while lastChoice.id == currentActivityChoice!.id {
                                currentActivityChoice = currentActivity.choices.randomElement()
                            }
                        }
                    }
                    lastShownRandomChoiceDic[currentActivity.id ?? ""] = currentActivityChoice
                    arrFinalBreakActivities[i].randomChoice = currentActivityChoice
                }
            }
        }
        
    }
    
    @objc func executeBreakActivities() {//   is any this is new in this func  we should also review this fucc "okClickedFromCustomMessage()"{
        
        addLog(text: "startBreakActivities")
//        allApiObject.isAnyErrorFoundInActivityCompletedApi = false
        self.breakTimer?.invalidate()
        self.breakTimer = nil
        if arrAllbreakActivities.count != 0 {

            reFillBreakActivitiesArray()
            
            if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
                self.setActivityTimer()//possible nahi hai
                return;
            }

            self.removeSubViews()
            currentState = ._ACTIVITY_
            
        
            self.performBreakActivities()
              
        }
        
    }
    func enableOfficeModeAndRestartBreakActivities(){
        addLog(text: "enableOfficeModeAndRestartBreakActivities")
        var officeModeEnableText = "Ok I'll give you some break activities that are appropriate to do in an office environment."
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            officeModeEnableText = activityPostponeInfo.value(forKey: "officeModeEnableText") as? String ?? officeModeEnableText
        }
        
        showCustomMessageView(msg: officeModeEnableText)
    }
    func showCustomMessageView(msg:String){
        addLog(text: "show Custom Message View")
        self.view.addSubview(getCustomMessageVcObject().view)
        self.view.addConstraints(subView: getCustomMessageVcObject().view)
        customMessageVcObj?.lblMessage.stringValue = msg
    }
    func okClickedFromCustomMessage(){
        addLog(text: "ok Clicked From CustomMessage")
        addLog(text: "enableOfficeMode from postpone nag")//
        SettingsManagerObject.isOfficeModeEnabled = true
        allApiObject.capturePosthog(event: "enable-office-mode", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))

   
        
        reFillBreakActivitiesArray()

        //  //

        self.removeSubViews()
        currentState = ._ACTIVITY_
        
        if currentAction == ._BRAIN_DUMP_{
            addLog(text: "ok Clicked From Custom Message:- performBreakActivities break activity ")
            self.performBreakActivities()
        }else{
            addLog(text: "ok Clicked From Custom Message:- list break activity ")
            self.btnAbort.isHidden = false
            self.stackViewTopButtons.isHidden = false
            thirdVcObj?.startBreakActivity()
            showBreakActivityListView()
           // firstViewControllerObj?.viewWillAppear()
        }

    }
    
    
    func performBreakActivities(){
        addLog(text: "perform Break Activities")
//        self.containerView.addSubview(thirdVcObj!.view)
//        self.containerView.addConstraints(subView: thirdVcObj!.view)
        self.btnAbort.isHidden = false
        self.stackViewTopButtons.isHidden = false
        
        if brainDumpWcObj != nil{
            if brainDumpWcObj!.window?.isVisible ?? false{
                brainDumpWcObj?.window?.close()
            }
        }
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        thirdVcObj?.startBreakActivity()
        mainWindowControllerObj?.window?.setIsVisible(true)
        showBlankWindowInSecondaryMonitor()
        
        
        
        currentAction = ._BRAIN_DUMP_//new work #502
        
        showBreaksBrainDump()

        
        
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showBreakActivityListView(){
        addLog(text: "showBreakActivityListView")
        currentAction = ._START_//new work #502
        self.removeSubViews()
        firstViewControllerObj?.isFirstTime = false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        firstViewControllerObj?.tblViewHabits.reloadData()
    }
    func emergencyStartDone(){
        addLog(text: "emergencyStartDone")
        btnAbort.isHidden = true
        self.stackViewTopButtons.isHidden = true
        removeSubViews()
        currentState = ._NOTHING_
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        
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
        
    }
    
    @IBAction func btnHiddenClicked(_ sender: Any) {
        //mainWindowControllerObj?.window?.close()
    }
}


