//
//  ViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa


class ViewController: NSViewController {
    
    @IBOutlet weak var btnAbort: Button!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var boxContainer: customBoxBg!
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

        showSmallTimerWindow(durationSeconds: 60, msg: "One minute timer ends in", isFocusBreak: false, currentTimerValue:0)
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
    
    @IBAction func btnAbortClicked(_ sender: Any) {
        addLog(text: "button Abort Clicked")
        lastCurrentState = currentState
        lastCurrentAction = currentAction
        btnAbort.isHidden = true
        if currentAction == ._INPROGRESS_{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        enableSystemSleep()
                        if timerViewcontrollerObj?.webView.isHidden == false{
                            if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                if #available(macOS 12.0, *) {
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
        if currentState == ._MORNING_HABIT_{
            
            refreshLastPostponeCount()
            
            if SettingsManagerObject.isEasySkipEnabled{
                mainWindowControllerObj?.window?.setIsVisible(false)
                hideBlankWindowInSecondaryMonitor()
                showEasyPostponeWindow()
                stopActivityTimer()
                if visualizeInstructionsVcObj != nil{
                    if visualizeInstructionsVcObj?.timer != nil{
                        if visualizeInstructionsVcObj?.timer?.isValid ?? false{
                            visualizeInstructionsVcObj?.timer?.invalidate()
                            visualizeInstructionsVcObj?.timer = nil
                        }
                    }
                }
                if currentHabitPlaying != nil{//todo baki sab bhi nil karna h kya  or timer rokna h kya
                    isAnyAllowedFocusModeActivityRunning = false
                    currentHabitPlaying = nil// beacuse there is no easy postpone cancel
                    closePupUpBlockIfVisible()
                    
                    arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                    arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                    arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                    arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                    
                    if smallCountDownWcObj != nil{// close timer window is easy postpone because there is no come back from easy postpone view
                        if smallCountDownWcObj?.window != nil{
                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                getSmallCountDownWindowObject().window!.close()
                            }
                        }
                    }
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
                mainWindowControllerObj?.window?.setIsVisible(false)
                hideBlankWindowInSecondaryMonitor()
                showEasyPostponeWindow()
                stopActivityTimer()
                if visualizeInstructionsVcObj != nil{
                    if visualizeInstructionsVcObj?.timer != nil{
                        if visualizeInstructionsVcObj?.timer?.isValid ?? false{
                            visualizeInstructionsVcObj?.timer?.invalidate()
                            visualizeInstructionsVcObj?.timer = nil
                        }
                    }
                }
                if currentHabitPlaying != nil{
                    isAnyAllowedFocusModeActivityRunning = false
                    currentHabitPlaying = nil// beacuse there is ono easy postpone cancel
                    closePupUpBlockIfVisible()
                    
                    arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                    arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                    arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                    arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                    
                    if smallCountDownWcObj != nil{// close timer window is easy postpone because there is no come back from easy postpone view
                        if smallCountDownWcObj?.window != nil{
                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                getSmallCountDownWindowObject().window!.close()
                            }
                        }
                    }
                }
                
            }else{
                stopActivityTimer()
                if activityPostponeCount == 0{
                    showAskPostponeView()
                }else{
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                        if SettingsManagerObject.isPasswordRequireInSkipEvening{
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
        }else if currentState == ._ACTIVITY_{
            
            if SettingsManagerObject.isEasySkipEnabled{
                if currentAction == ._START_{
                    mainWindowControllerObj?.window?.setIsVisible(false)
                    hideBlankWindowInSecondaryMonitor()
                    showEasyPostponeWindow()
                    if currentActivityPlaying != nil{
                        isAnyAllowedFocusModeActivityRunning = false
                        currentActivityPlaying = nil// beacuse there is ono easy postpone cancel
                        closePupUpBlockIfVisible()
                        
                        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                        
                        if smallCountDownWcObj != nil{// close timer window is easy postpone because there is no come back from easy postpone view
                            if smallCountDownWcObj?.window != nil{
                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                    getSmallCountDownWindowObject().window!.close()
                                }
                            }
                        }
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
                        if SettingsManagerObject.isPasswordRequireInSkipEvening{
                            showPasswordView()
                        }else{
                            showAbortStartView()
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
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                self.containerView.addSubview(thirdVcObj!.view)
                self.containerView.addConstraints(subView: thirdVcObj!.view)
                thirdVcObj?.startBreakActivity()
                currentState = ._ACTIVITY_
                currentAction = ._START_
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                
                timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: timerViewcontrollerObj?.currentDurationInSeconds ?? 0, name: timerViewcontrollerObj?.currentActicityTitle ?? "", url: timerViewcontrollerObj?.currentUrl)
                currentState = ._ACTIVITY_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._ACTIVITY_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                break
            }
        }else if lastCurrentState == ._MORNING_HABIT_{
            btnAbort.isHidden = false
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllMorningHabitsAbortCancel()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!)
                currentState = ._MORNING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
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
            }
            
        }else if lastCurrentState == ._EVENING_HABIT_{
            btnAbort.isHidden = false
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllEveningHabitsAbortCancel()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!)
                currentState = ._EVENING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
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
            }
            
        }else if lastCurrentState == ._SHUTOFFMAC_{
            btnAbort.isHidden = false
            removeSubViews()
            shutOffMac()
        }else if lastCurrentState == ._FOCUS_SUMMARY_{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            self.btnAbort.isHidden = true
            self.removeSubViews()
            self.containerView.addSubview(focusSummaryVcObj!.view)
            self.containerView.addConstraints(subView: focusSummaryVcObj!.view)
            currentState = ._FOCUS_SUMMARY_
        }
    }
    
    
    func showAbortConfirmationView(){
        addLog(text: "showAbortConfirmationView")
        btnAbort.isHidden = true
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
        removeSubViews()
        containerView.addSubview(abortDoneVcObj!.view)
        containerView.addConstraints(subView: abortDoneVcObj!.view)
        abortDoneVcObj?.startTimer()
        currentState = ._ABORT_
    }
    func disableApp(){
        addLog(text: "App Deactivated by user (Aborted)")
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsAppEnabled)
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
        btnAbort.isHidden = true
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
        btnAbort.isHidden = true
        removeSubViews()

        containerView.addSubview(getAskAppWorkVcObject().view)
        containerView.addConstraints(subView: getAskAppWorkVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showAskHabitSkipEasinessVc(){
        addLog(text: "show Ask Habit Skip Easiness Vc.")
        btnAbort.isHidden = true
        removeSubViews()

        containerView.addSubview(getHabitSkipEasinessVcObject().view)
        containerView.addConstraints(subView: getHabitSkipEasinessVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showOnboardingBlockedUrlsVc(){
        addLog(text: "show Onboarding Blocked Urls.")
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(getOnboardingBlockedUrlsVcObject().view)
        containerView.addConstraints(subView: getOnboardingBlockedUrlsVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    func showVisualizeInstructionsVc(){
        addLog(text: "show Visualize Instructions Vc.")
        btnAbort.isHidden = false
        removeSubViews()
        currentAction = ._VISUALIZE_
        containerView.addSubview(getvisualizeInstructionsObject().view)
        containerView.addConstraints(subView: getvisualizeInstructionsObject().view)
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
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrAllEveningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllEveningHabits:- Activity Postpone In Running State:- start direct \(arrAllEveningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false
            
            
            currentHabitIndex = 0
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!, currentHabit: arrAllEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastSavedActivityId == arrAllEveningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllEveningHabits:- app terminate In Running State:- start direct \(arrAllEveningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false

            currentHabitIndex = 0
            if lastSavedActivityProgress > arrAllEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!, currentHabit: arrAllEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
        }else{
            addLog(text:"func showAllEveningHabits:- show All Evening Habits")
            isLastActivityStoppedInRunningState = false
            isPromptToRememberHabitShowedInLastHabit = false
            btnAbort.isHidden = false
            removeSubViews()
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
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrAllMorningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllMorningHabits:- Activity Postpone In Running State:- start direct \(arrAllMorningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false
            
            
            currentHabitIndex = 0
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!, currentHabit: arrAllMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrAllMorningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllMorningHabits:- app terminate In Running State:- start direct \(arrAllMorningHabits[0].name ?? "") in running state")
            removeSubViews()
            btnAbort.isHidden = false

            currentHabitIndex = 0
            if lastSavedActivityProgress > arrAllMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!, currentHabit: arrAllMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
        }else{
            addLog(text:"func showAllMorningHabits:- show All Morning Habits")
            isLastActivityStoppedInRunningState = false
            isPromptToRememberHabitShowedInLastHabit = false
            lastShownRandomChoiceDic = [String:activityChoice]()
            btnAbort.isHidden = false
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
        removeSubViews()
        currentHabitIndex = 0
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!, currentHabit: arrAllMorningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-morning-routine", metadata: ["routine-type":"morning_routine"])
    }
    
    func startFirstEveningHabit() {
        addLog(text:"current startFirstEveningHabit called")
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex = 0
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!, currentHabit: arrAllEveningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-evening-routine", metadata: ["routine-type":"evening_routine"])
    }
    func startBreathing() {
        addLog(text:"current startBreathing called")
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startBreathing()
        currentState = ._BREATHING_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-first-routine", metadata: ["routine-type":"first_routine"])
    }
    
    func breathingOver() {
        addLog(text:"current breathing Habit Over called")
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.breathingFinished()
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
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()

        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
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
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
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
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrAllMorningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- Activity Postpone In Running State:- start direct \(arrAllMorningHabits[index].name ?? "") in running state")
            
            currentHabitIndex = index
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!, currentHabit: arrAllMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
            
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrAllMorningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- app terminate In Running State:- start direct \(arrAllMorningHabits[index].name ?? "") in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrAllMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!, currentHabit: arrAllMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- morningHabitFinishedAndStartIncompleteNew")
            isLastActivityStoppedInRunningState = false
            containerView.addSubview(thirdVcObj!.view)
            containerView.addConstraints(subView: thirdVcObj!.view)
            currentHabitIndex = index-1
            thirdVcObj!.morningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
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
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
        removeSubViews()
        //        if currentHabitIndex < arrAllEveningHabits.count-1 {
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
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        closePupUpBlockIfVisible()
        
        appdelegate?.timerAllowUrlForActivity?.invalidate()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        btnAbort.isHidden = false
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
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrAllEveningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- Activity Postpone In Running State:- start direct\(arrAllEveningHabits[index].name ?? "")in running state")
            
            currentHabitIndex = index
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!, currentHabit: arrAllEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastSavedActivityId == arrAllEveningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- app terminate In Running State:- start direct \(arrAllEveningHabits[index].name ?? "") in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrAllEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            containerView.addSubview(timerViewcontrollerObj!.view)
            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!, currentHabit: arrAllEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- eveningHabitFinishedAndStartIncompleteNew")
            isLastActivityStoppedInRunningState = false
            containerView.addSubview(thirdVcObj!.view)
            containerView.addConstraints(subView: thirdVcObj!.view)
            currentHabitIndex = index-1
            thirdVcObj!.eveningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
        }
    }
    func eveningHabitFinishShowShutOff(){
        addLog(text: "evening habit Finished")
        shutOffMac()

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
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.activityFinished(index: currentActivityIndex)
        currentState = ._ACTIVITY_
        currentAction = ._END_
    }
    
    func changeMorningHabit() {
        addLog(text:"current change Morning Habit called")
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!, currentHabit: arrAllMorningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    func changeEveningHabit() {
        addLog(text:"current change Evening Habit called")
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!, currentHabit: arrAllEveningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    
    func startCurrentActivity() {
        allApiObject.capturePosthog(event: "start-break-activity", metadata: ["routine-type":"break_activity"])
        addLog(text:"start Current Activity called")
        btnAbort.isHidden = false
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        if isMandatoryActivityGoing{
            let currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
            
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
            }else{//random choice
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }
            }
            
            
        }else{
            let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
            }else{//random choice
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }
            }
            
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    
    
    func changeActivity() {
        addLog(text:"current change Activity called")
        btnAbort.isHidden = false
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
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
                    }else{
                        if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }else if let randomChoice = currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }
                    }
                    
                }else{
                    let currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
                    
                    if !currentActivity.isRandomChoice{
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
                    }else{
                        if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }else if let randomChoice = currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                        }
                    }
                }
            }else{
                let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                
                if !currentActivity.isRandomChoice{
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
                }else{
                    if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                    }else if let randomChoice = currentActivity.choices.randomElement(){
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                    }
                }
            }
        }else{
            currentActivityIndex += 1
            let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
            
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
            }else{
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
                }
            }
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    
    func habitsFinishedUnlockMachine() {
        addLog(text: "morning habit Finished")
        btnAbort.isHidden = true
        removeSubViews()
        lblMessage.isHidden = false
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
        }
        currentHabitIndex = -1
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
//        if allApiObject.isAnyErrorFoundInActivityCompletedApi{//comment kiya hai 
//            allApiObject.isAnyErrorFoundInActivityCompletedApi = false
//            var activitiesSyncErrorText = "Focus Bear was not able to sync the activities' statistics due to bad internet."
//            if let common = configjson.value(forKey: "common") as? NSDictionary{
//                activitiesSyncErrorText = common.value(forKey: "activitiesSyncErrorText") as? String ?? activitiesSyncErrorText
//            }
//            showCustomNotificationWindow(msg: activitiesSyncErrorText)
//        }
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
    
    func setActivityTimer(){
        addLog(text: "Break Activity Timer reset Done.")
        if arrAllbreakActivities.count != 0 {
            DispatchQueue.global().sync {
                print("breakAfterMinutesxxxx")
                if self.breakTimer != nil{
                    self.breakTimer?.invalidate()
                    self.breakTimer = nil
                }
                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(breakAfterMinutes*60), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)//todo breakAfterMinutes*60 kro

                RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
            }
        }
    }
    var isBreakActivityPostponeInsideAllowedHabit = false// using this beacuse we dont want reset activity timer again (in resuming habit) if user has postponed activity inside allow app habit 
    func postponeBreakActivitiesFor(minutes:Int){
        addLog(text: "postpone Break Activities, Timer reset Done:- \(minutes) minutes")
        btnAbort.isHidden = true
        
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
            if arrAllMorningHabits.count != 0 {
                let infoDic:[String:Any] = ["sequenceId":arrAllMorningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":Date()]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
                print(infoDic)
            }
        }else if state == ._EVENING_HABIT_{
            if arrAllEveningHabits.count != 0 {
                
                var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                
                let curreentDate = Date()
                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate

                }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time

                }
                
                let infoDic:[String:Any] = ["sequenceId":arrAllEveningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":startDate]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
                print(infoDic)
            }
        }
    }
    func refreshLastPostponeCount(){
        var lastSavedPostponeTime = Date()
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
            if arrAllMorningHabits.count != 0 {
                if lastSavedSequenceId == arrAllMorningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            if arrAllEveningHabits.count != 0 {
                if lastSavedSequenceId == arrAllEveningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
                }
            }
        }
    }
    func postponeMorningHabitFor(minutes:Int){
        addLog(text: "postpone morning habits, Timer reset Done:- \(minutes) minutes")
        
        
        savePostpneCount(state: ._MORNING_HABIT_)
        
        if currentAction == ._INPROGRESS_{
            isLastActivityStoppedInRunningState = true
            lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
        }else{
            isLastActivityStoppedInRunningState = false
            lastActivityRunningId = ""
        }
        
        btnAbort.isHidden = true
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
        
        if arrAllMorningHabits.count != 0 {
            DispatchQueue.global().sync{//async {
                if self.postponeTimer != nil{
                    self.postponeTimer?.invalidate()
                    self.postponeTimer = nil
                }
                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.resumeMorningHabit), userInfo: nil, repeats: false)//todo  minutes*60 kro TimeInterval(minutes*60)
                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
            }
        }
    }
    func postponeEveningHabitFor(minutes:Int){
        addLog(text: "postpone evening habits, Timer reset Done:- \(minutes) minutes")
        
        savePostpneCount(state: ._EVENING_HABIT_)
        
        if currentAction == ._INPROGRESS_{
            isLastActivityStoppedInRunningState = true
            lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
        }else{
            isLastActivityStoppedInRunningState = false
            lastActivityRunningId = ""
        }
        
        btnAbort.isHidden = true
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
        if arrAllEveningHabits.count != 0 {
            DispatchQueue.global().sync{//async {
                if self.postponeTimer != nil{
                    self.postponeTimer?.invalidate()
                    self.postponeTimer = nil
                }
                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.resumeEveningHabit), userInfo: nil, repeats: false)//todo  minutes*60 kroTimeInterval(minutes*60)
                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
            }
        }
    }
    
    func postponeFocusSummaryFor(minutes:Int){
        addLog(text: "postpone Focus Summary Done:- \(minutes) minutes")
        btnAbort.isHidden = true
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
        removeSubViews()
        //        lblMessage.isHidden = false
        //        isBreakActivitiesGoing = false
        currentActivityIndex = -1
        unlockMachine()
        currentState = ._NOTHING_
        
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
                return
            }
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            checkLogFileRotation()

            if isFocusModeOn() && isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
                self.setActivityTimer()
                addLog(text: "Pomodoro mode is On: Break Activities cancelled.")
                return
            }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
                self.setActivityTimer()
                addLog(text: "Super Pomodoro mode is On: Break Activities cancelled.")
                return
            }
            
//            if avmonitor.isMicOn(){
//                self.setActivityTimer()
//                addLog(text: "Mic is in use, Break Activities cancelled.")
//                return;
//            }
//            if avmonitor.isACameraOn(){
//                self.setActivityTimer()
//                addLog(text: "Camera is in use, Break Activities cancelled.")
//                return;
//            }
//            if isPreventUserIdleDisplaySleepOn(){
//                self.setActivityTimer()
//                addLog(text: "PreventUserIdleDisplaySleep is On: Break Activities cancelled.")
//                return;
//            }
            
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
                            if timerViewcontrollerObj?.webView.isHidden == false{
                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                    
                    if currentHabitPlaying != nil{
                        isAnyAllowedFocusModeActivityRunning = false
                        currentHabitPlaying = nil//todo baki sab bhi nil krna hai kya or time bhi rokna hai kya
                        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                        
                        closePupUpBlockIfVisible()
                        
                        if smallCountDownWcObj != nil{// close timer window is easy postpone because there is no come back from easy postpone view
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
                            if timerViewcontrollerObj?.webView.isHidden == false{
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
                        
                        if smallCountDownWcObj != nil{// close timer window is easy postpone because there is no come back from easy postpone view
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
            showBreakWarningWindow()
            currentState = ._ACTIVITY_
        }
    }
        
    @objc func executeBreakActivities() {
        
        addLog(text: "startBreakActivities")
//        allApiObject.isAnyErrorFoundInActivityCompletedApi = false
        self.breakTimer?.invalidate()
        self.breakTimer = nil
        if arrAllbreakActivities.count != 0 {
            self.btnAbort.isHidden = false
            //                isBreakActivitiesGoing = true
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
            if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
                self.setActivityTimer()//possible nahi hai
                return;
            }
            if isAnyMandatoryActivityIncluded{
                isMandatoryActivityGoing = true
                currentActivityIndex = 0
                if arrActivitiesExcludeInEveryBreak.count != 0{
                    randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
                }
            }else{
                currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))// 
            }
            
            self.removeSubViews()
            currentState = ._ACTIVITY_
            currentAction = ._START_
            
            self.performBreakActivities()
            
            
//            addLog(text: "getLastActivityInfo break activity")
//            allApiObject.getLastActivityInfo(completionHandler: { json in
//                DispatchQueue.main.async {
//                    if json != nil{
//                        print(json!)
//                        if let currentActivitySequence = json?.value(forKey: "current_activity_sequence") as? NSDictionary{
//                            if let sequenceId = currentActivitySequence.value(forKey: "id") as? String{
//                                addLog(text: "forceCompleteCurrentSequence break activity")
//                                var isForToday = false
//                                if let current_activity_assigned_at = json?.value(forKey: "current_activity_assigned_at") as? String{
//                                    if let activityAssignedDate = getDateFromStringInUtc(date: current_activity_assigned_at, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
//                                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
//                                        if activityAssignedDate.compare(startDate) == .orderedDescending{
//                                            isForToday = true
//                                        }
//                                    }
//                                }
//
//                                /*// comment kiya hai abhi shayad remove hi krna pde
//                                allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
//                                    print("start new sequense")
//                                    // and strt break activity
//                                    DispatchQueue.main.async {
//                                        addLog(text: "performBreakActivities break activity")
//                                        self.performBreakActivities()
//                                    }
//                                })
//                                */
//
//                            }else{
//                                addLog(text: "performBreakActivities break activity:- sequenceId not found")
//                                self.performBreakActivities()
//                            }
//                        }else{
//                            addLog(text: "performBreakActivities break activity:- current_activity_sequence not found as dictionary")
//                            self.performBreakActivities()
//                        }
//
//
//                    }else{
//                        addLog(text: "performBreakActivities break activity:- get Last Activity Info is nil")
//                        self.performBreakActivities()
//                    }
//                }
//            }
//            )
            
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
        
        
        
        self.btnAbort.isHidden = false
        
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
        
        
        
        if isAnyMandatoryActivityIncluded{
            isMandatoryActivityGoing = true
            currentActivityIndex = 0
            if arrActivitiesExcludeInEveryBreak.count != 0{
                randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
            }
        }else{
            currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
        }
        // }
        self.removeSubViews()
        currentState = ._ACTIVITY_
        currentAction = ._START_
        
        
        addLog(text: "ok Clicked From Custom Message:- performBreakActivities break activity ")
        self.performBreakActivities()
        
        
    }
    func performBreakActivities(){
        addLog(text: "perform Break Activities")
        self.containerView.addSubview(thirdVcObj!.view)
        self.containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj?.startBreakActivity()
        mainWindowControllerObj?.window?.setIsVisible(true)
        showBlankWindowInSecondaryMonitor()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func emergencyStartDone(){
        addLog(text: "emergencyStartDone")
        btnAbort.isHidden = true
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


