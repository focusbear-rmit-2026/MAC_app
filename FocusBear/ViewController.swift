//
//  ViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.


import Cocoa


class ViewController: NSViewController {
    
    
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var splitViewItemRightView: NSView!
    @IBOutlet weak var splitViewItemLeftView: NSView!
    @IBOutlet weak var boxTopButtons: NSBox!
    // @IBOutlet weak var lblCurrentDateTime: NSTextField!
    @IBOutlet weak var boxMinimize: NSBox!
    @IBOutlet weak var stackViewTopButtons: NSStackView!
    
    //    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var boxContainer: customBoxBg!
    
    
    var topButtonsTrackingArea: NSTrackingArea?
    //    var breakTimer: Timer?
    //    var postponeTimer: Timer?
    //    var postponeNotificationTimer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        lblMessage.stringValue = "OK - Stay focused throughout the day!"
        //        lblMessage.isHidden = true
        //        btnAbort.title = "Please spare me"
        //        btnAbort.borderWidth = 2
        //        if let common = configjson.value(forKey: "common") as? NSDictionary{
        //            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
        //            btnAbort.title = common.value(forKey: "buttonAbortText") as? String ?? btnAbort.title
        //        }
        //        isMainWindowLoaded = true
        //
        //
        //        btnAbort.buttonColor = NSColor(red: 255/255, green: 244/255, blue: 233/255, alpha: 1).cgColor
        
        topButtonsTrackingArea = NSTrackingArea.init(rect: stackViewTopButtons.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        stackViewTopButtons.addTrackingArea(topButtonsTrackingArea!)
        boxMinimize.isHidden = true
        
        
        
        
        
        splitViewItemLeftView.subviews.removeAll()
        splitViewItemLeftView.addSubview(getLeftMenuVcObject().view)
        splitViewItemLeftView.addConstraints(subView: getLeftMenuVcObject().view)
        //showHabitsView()
        //        showDashboardView()
//        setupLeftPaneWidthConstraint(for: splitView, initialWidth: 230)
        
        splitViewItemLeftView.addObserver(self, forKeyPath: "frame", options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            let width = (object as? NSView)?.frame.width ?? 0
            print("Left view width changed to \(width)")
            if width < 100{
                leftMenuVcObj?.boxMainItems.titleLabel.isHidden = true
                leftMenuVcObj?.boxToolsItems.titleLabel.isHidden = true
                leftMenuVcObj?.boxPreferences.titleLabel.isHidden = true
            }else{
                leftMenuVcObj?.boxMainItems.titleLabel.isHidden = false
                leftMenuVcObj?.boxToolsItems.titleLabel.isHidden = false
                leftMenuVcObj?.boxPreferences.titleLabel.isHidden = false
            }
        }
    }
    //    var dateTimeTimer:Timer?
    //    func startDateTimer() {
    //        lblCurrentDateTime.isHidden = false
    //        if dateTimeTimer != nil{
    //            dateTimeTimer?.invalidate()
    //            dateTimeTimer = nil
    //            setDateTime()
    //        }
    //        setDateTime()
    //        DispatchQueue.main.async {
    //            self.dateTimeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.setDateTime), userInfo: nil, repeats: true)
    //            RunLoop.main.add((self.dateTimeTimer!), forMode: RunLoop.Mode.common)
    //        }
    //    }
    //
    //    @objc func setDateTime(){
    //        if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
    //            print(dict)
    //            lblCurrentDateTime.stringValue = getStringFromDate(date: Date(), dateFormat: dict["DateFormat"] as? String ?? "EEE d MMM h:mm:ss")
    //        }else{
    //            lblCurrentDateTime.stringValue = getStringFromDate(date: Date(), dateFormat: "EEE d MMM h:mm:ss")
    //        }
    //    }
    var shouldIgnoreViewWilDisappear = false
    var lastSmallWindowFrame:NSRect?
    func checkIsFullScreenNeeded() {
        if checkIsFullScreenEnabled(){
            if !(self.view.window?.styleMask.contains(.fullScreen) ?? false){// Don’t do this if the user is already in fullscreen. Wait until the user toggles back to a small screen, then check the setting again.
                shouldIgnoreViewWilDisappear = true
                mainWindowControllerObj?.showFullSizeWindow()// This will cause the viewWillDisappear function to be called
                boxTopButtons.isHidden = false
                lastSmallWindowFrame = self.view.window?.frame
                shouldIgnoreViewWilDisappear = false
            }
        }else{
            mainWindowControllerObj?.showSmallSizeWindow()
            boxTopButtons.isHidden = true
        }
        
        if checkIsFullScreenEnabled(){
            if !(self.view.window?.styleMask.contains(.fullScreen) ?? false){// Don’t do this if the user is already in fullscreen. Wait until the user toggles back to a small screen, then check the setting again.
                setframe()
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.setframe()
                    }
                }
            }
        }else{
            if self.view.window != nil{
                if isBreakActivityShowingWhileMeeting && currentState == ._MICRO_BREAK_{
                    let screenList = NSScreen.screens
                    for screen in screenList {
                        let screenHeight = screen.frame.height
                        let screenWidth = screen.frame.width
                        let width = self.view.window?.minSize.width ?? 1000
                        let height = self.view.window?.minSize.height ?? 1000
                        
                        let x = ((screenWidth/2) - (width/2))
                        let y = ((screenHeight/2) - (height/2))
                        
                        let newFrame = NSRect(origin: NSPoint(x: x, y: y), size: self.view.window!.minSize)
                        self.view.window?.setFrame(newFrame, display: true)
                        break;
                    }
                    
                }else{
                    if let screen = self.view.window?.screen{ //
                        self.view.window?.setFrame(screen.visibleFrame, display: true, animate: false)
                    }else{
                        let screenList = NSScreen.screens
                        for screen in screenList {
                            self.view.window?.setFrame(screen.visibleFrame, display: true)
                            break;
                        }
                    }
                }
            }
        }
    }
    
    func showSmallScreen(showMinimumSize:Bool = false){
        mainWindowControllerObj?.showSmallSizeWindow()
        let screenList = NSScreen.screens
        
        if !(self.view.window?.styleMask.contains(.fullScreen) ?? false) && showMinimumSize{
            self.view.window?.setContentSize(NSSize(width: mainWindowControllerObj?.smallWindowAvgWidth ?? 500, height: mainWindowControllerObj?.smallWindowAvgHeight ?? 500))
            self.view.window?.center()
        }else{
            if let screen = self.view.window?.screen{ //
                self.view.window?.setFrame(screen.visibleFrame, display: true, animate: false)
            }else{
                for screen in screenList {
                    self.view.window?.setFrame(screen.visibleFrame, display: true, animate: false)
                    break;
                }
            }
        }
        boxTopButtons.isHidden = true
    }
    //    override func viewWillDisappear() {
    //        lblCurrentDateTime.isHidden = true
    //        dateTimeTimer?.invalidate()
    //    }
    @objc func setframe() {
        let screenList = NSScreen.screens
        for screen in screenList {
            self.view.window?.setFrame(NSMakeRect(NSMinX(screen.frame), NSMinY(screen.frame), NSWidth(screen.frame), NSHeight(screen.frame)), display: true) //  uncomment this line
//            self.view.window?.setFrame(NSMakeRect(100, 100, NSWidth(screen.frame) - 200, NSHeight(screen.frame) - 200) , display: true)//  comment this //  do this
            
            break;
        }
    }//
    
    override func viewWillDisappear() {
        if !shouldIgnoreViewWilDisappear{
            removeSubViews()
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
        addLog(text: "[user-action] button Minimize Clicked")// added on 10/4/25 in 1.21.356
        
        let views = getHabitsVcObject().view.subviews
        if views.count != 1{// it means sub views are added so nothing will happen, user will need to close subviews first(logquantity view, password box)
            return
        }
        
        habitsVcObj?.abortCurrentState()
    }

    
    func newUrlOrAppAdded(){// show permissions if not added 
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser)
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            let alertWarning = NSAlert()
            alertWarning.setSharingType()
            alertWarning.messageText = "Do you want to block distractions?"
            alertWarning.informativeText = "You can block distracting websites and distracting apps. You will need to allow permissions to block distracting websites."
            var buttonBlockText = "Yeah - block them!"
            var buttonNoText = "No thanks"

            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
                alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningSetDistractionsInfo") as? String ?? alertWarning.informativeText
                buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
                buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
            }
            
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                
                if modalResponse == .alertFirstButtonReturn{
                    showExplainingPermissionsWindow(showingFromPomodoro: false)
                    self.view.window?.close()
                }
                
            })
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            return;
        }
    }
    
    
    
    
    
    //    @objc func showFocusSummaryView(){
    //        appdelegate!.checkSystemTimeAndShowWindow()
    //        if startTime == nil || shutOffTime == nil{
    //            return;
    //        }
    //        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    //
    //        let curreentDate = Date()
    //        if curreentDate > shutOffdate{
    //
    //        }else if curreentDate < startDate{
    //
    //        }else{// not shutoff time
    //            currentState = ._NOTHING_
    //            if mainWindowControllerObj?.window?.isVisible ?? false{
    //                self.view.window?.close()
    //                hideBlankWindowInSecondaryMonitor()
    //            }
    //            return;
    //        }
    //        allActivityTodaySummaryData = nil
    //        currentState = ._FOCUS_SUMMARY_
    //        if SettingsManagerObject.isGeekModeEnabled{
    //            allApiObject.getAllActivityDaySummary(completionHandler: {dic in
    //                DispatchQueue.main.async {
    //                    if !(mainWindowControllerObj?.window!.isVisible)! {
    //                        mainWindowControllerObj?.showWindow(self)
    //                    }
    //                    showBlankWindowInSecondaryMonitor()
    //
    //                    addLog(text: "Showing Focus Summary")
    //                    self.hideCloseButtons()
    //                    self.removeSubViews()
    //                    self.containerView.addSubview(focusSummaryVcObj!.view)
    //                    self.containerView.addConstraints(subView: focusSummaryVcObj!.view)
    //                    focusSummaryVcObj!.reloadData()
    //                }
    //            })
    //        }else{
    //            if !(mainWindowControllerObj?.window!.isVisible)! {
    //                mainWindowControllerObj?.showWindow(self)
    //            }
    //            showBlankWindowInSecondaryMonitor()
    //
    //            addLog(text: "Showing Focus Summary: simnple mode")
    //            self.hideCloseButtons()
    //            self.removeSubViews()
    //            self.containerView.addSubview(focusSummaryVcObj!.view)
    //            self.containerView.addConstraints(subView: focusSummaryVcObj!.view)
    //            focusSummaryVcObj!.reloadData()
    //        }
    //
    //
    //    }
    
    //    @objc func showDayEndFocusCompletedView(){
    //        currentState = ._FOCUS_SUMMARY_
    //        if !(mainWindowControllerObj?.window!.isVisible)! {
    //            mainWindowControllerObj?.showWindow(self)
    //        }
    //        showBlankWindowInSecondaryMonitor()
    //
    //        addLog(text: "show Day End Focus Completed View")
    //        self.hideCloseButtons()
    //        self.removeSubViews()
    //        self.containerView.addSubview(focusCompletedFullScreenVcObj!.view)
    //        self.containerView.addConstraints(subView: focusCompletedFullScreenVcObj!.view)
    //    }
    
    //    @objc func showMorningRoutineFocusCompletedView(){
    //        currentState = ._MORNING_HABIT_
    //        if !(mainWindowControllerObj?.window!.isVisible)! {
    //            mainWindowControllerObj?.showWindow(self)
    //        }
    //        showBlankWindowInSecondaryMonitor()
    //
    //        addLog(text: "show Morning Routine Focus Completed View")
    //        self.hideCloseButtons()
    //        self.removeSubViews()
    //        self.containerView.addSubview(focusCompletedFullScreenVcObj!.view)
    //        self.containerView.addConstraints(subView: focusCompletedFullScreenVcObj!.view)
    //    }
    
    //    @objc func showCustomRoutineFocusCompletedView(){
    //        currentState = ._CUSTOM_ROUTINE_
    //        if !(mainWindowControllerObj?.window!.isVisible)! {
    //            mainWindowControllerObj?.showWindow(self)
    //        }
    //        showBlankWindowInSecondaryMonitor()
    //
    //        addLog(text: "show custom Routine Focus Completed View")
    //        self.hideCloseButtons()
    //        self.removeSubViews()
    //        self.containerView.addSubview(focusCompletedFullScreenVcObj!.view)
    //        self.containerView.addConstraints(subView: focusCompletedFullScreenVcObj!.view)
    //    }
    
    @objc func showLoaderView(){
        addLog(text: "Showing Loader")
        self.view.addSubview(getLoaderVcObj().view)
        self.view.addConstraints(subView: getLoaderVcObj().view)
    }
    
    @objc func hideLoaderView(){
        addLog(text: "Hide Loader")
        if loaderVcPbj != nil{
            if self.view.subviews.contains(loaderVcPbj!.view){
                loaderVcPbj?.view.removeFromSuperview()
            }
        }
    }
    
    //    var timerGiveOneMoreMinut:Timer?
    //    func giveOneMoreMinuteBeforeShutOffMac(){// state _FOCUS_SUMMARY_hi rahne denge taki kuch or bich mai naa aay
    //        mainWindowControllerObj?.window?.close()
    //        hideBlankWindowInSecondaryMonitor()
    //
    //        DispatchQueue.global().sync {
    //            self.timerGiveOneMoreMinut = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.showFocusSummaryViewAgain), userInfo: nil, repeats: false)
    //            RunLoop.main.add((self.timerGiveOneMoreMinut!), forMode: RunLoop.Mode.common)
    //        }
    //        var msg = "One minute timer ends in"
    //        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
    //            if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
    //                msg = focusSummaryInfo.value(forKey: "oneMinuteTimerText") as? String ?? msg
    //            }
    //        }
    //
    //        showSmallTimerWindow(durationSeconds: 60, msg: msg, isFocusBreak: false, currentTimerValue:0)
    //    }
    
    //    @objc func showFocusSummaryViewAgain(){
    //        DispatchQueue.main.async {
    //            addLog(text: "Showing Focus Summary again")
    //
    //            self.showFocusSummaryView()
    //        }
    //    }
    
    //    func showLogQuantityView(){
    //        allApiObject.capturePosthog(event: "log-quantity-view-shown", metadata: [:])
    //        self.view.addSubview(logQuantityVcObj!.view)
    //        self.view.addConstraints(subView: logQuantityVcObj!.view)
    //    }
    //    func showTakeNotesView(){
    //        allApiObject.capturePosthog(event: "take-notes-view-shown", metadata: [:])
    //        self.view.addSubview(getTakeActivityNotesVcObj().view)
    //        self.view.addConstraints(subView: getTakeActivityNotesVcObj().view)
    //    }
    //
    //    func showFocusCompletedView(){
    //        allApiObject.capturePosthog(event: "focus-completed-for-activity-view-shown", metadata: [:])
    //        self.view.addSubview(getFocusCompletedForActivityVcObj().view)
    //        self.view.addConstraints(subView: getFocusCompletedForActivityVcObj().view)
    //    }
    //
    func checkIsAnyUserInputSubViewAdded()->Bool{
        if logQuantityVcObj != nil{
            if self.view.subviews.contains(logQuantityVcObj!.view){
                return true
            }
        }
        
        if takeActivityNotesVcObj != nil{
            if self.view.subviews.contains(takeActivityNotesVcObj!.view){
                return true
            }
        }
        
        if focusCompletedForActivityVcObj != nil{
            if self.view.subviews.contains(focusCompletedForActivityVcObj!.view){
                return true
            }
        }
        return false
    }
    
    //    func showSkipHabitView(){
    //        addLog(text: "show SkipHabit View")
    //        self.view.addSubview(getSkipHabitVcObject().view)
    //        self.view.addConstraints(subView: getSkipHabitVcObject().view)
    //        getSkipHabitVcObject().resetView()
    //    }
    //    func showWhySkipHabitView(){
    //        addLog(text: "show whySkipHabit View")
    //        self.view.addSubview(getWhySkipHabitVcObject().view)
    //        self.view.addConstraints(subView: getWhySkipHabitVcObject().view)
    //    }
    //
    //    func showAskPostponeView(){
    //        addLog(text: "show AskPostpone View")
    //        self.view.addSubview(getAskPostponeVcObject().view)
    //        self.view.addConstraints(subView: getAskPostponeVcObject().view)
    //        getAskPostponeVcObject().resetView()
    //    }
    
    //    func abortOnboardingWork(){
    //        allApiObject.capturePosthog(event: "onboarding-skip-clicked", metadata: [:])
    //        hideCloseButtons()
    //        if currentAction == ._INPROGRESS_{
    //            if timerViewcontrollerObj != nil {
    //                if timerViewcontrollerObj?.timer != nil {
    //                    timerViewcontrollerObj?.timer?.invalidate()
    //                    enableSystemSleep()
    //                    if timerViewcontrollerObj?.isVideoLodded ?? false{
    //                        if !(timerViewcontrollerObj?.isActivityPaused ?? false){
    //                            if #available(macOS 12.0, *) {
    //                                if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
    //                                    timerViewcontrollerObj?.btnTabVideoClicked(self)
    //                                }
    //                                timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
    //                            } else {
    //                                // Fallback on earlier versions
    //                                timerViewcontrollerObj?.loadBlankUrl()
    //                            }
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //
    //        if currentState == ._ASK_APP_WORK_{
    ////            if askAppWorkVcObj != nil{
    ////                self.abortOboardingWorkTime()
    ////                return;
    ////            }
    //
    ////            if containerView.subviews.contains(getInstallHabitPacksVcObj().view){//
    //////                abortOboardingHabitPack()
    ////
    ////            }
    ////
    ////            if containerView.subviews.contains(getAdditionalGoalsVcObject().view){
    //////                abortOboardingHabitPack()
    ////
    ////            }
    ////            if containerView.subviews.contains(getAskWorkTimeVcObject().view){
    ////
    ////
    ////            }
    //
    //            abortOboardingWorkTime()
    //
    //        }else if currentState == ._BREATHING_{
    //            isFirstRun = true
    //            breathingFinishedUnlockMachine()
    //        }
    //    }
    
    //    func abortOboardingWorkTime(){
    //        if UserDefaults.standard.object(forKey: kUserdefaultsStartupTimeFromOnboarding) == nil{
    //            UserDefaults.standard.set(defaultStartTime, forKey: kUserdefaultsStartupTimeFromOnboarding)
    //            UserDefaults.standard.set(defaultShutDownTime, forKey: kUserdefaultsShutOffTimeFromOnboarding)
    //        }
    //
    //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
    //
    //        isFirstRun = true
    //        breathingFinishedUnlockMachine()
    //    }
    //    func abortOboardingHabitPack(){
    //        if habitPacksData != nil{
    //            if habitPacksData!.count != 0{
    //                let pack = habitPacksData![0]
    //                let id = pack["id"] as? String ?? ""
    //                if !id.isEmpty{
    //                    UserDefaults.standard.set(id, forKey: kUserdefaultsPackIdSelected)
    //                }
    //            }
    //        }
    //    }
    //    func stopActivityCountDownTimer(){
    //        if currentAction == ._INPROGRESS_{
    //            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
    //                if timerViewcontrollerObj != nil {
    //                    if timerViewcontrollerObj?.timer != nil {
    //                        timerViewcontrollerObj?.timer?.invalidate()
    //                        enableSystemSleep()
    //                        if timerViewcontrollerObj?.isVideoLodded ?? false{
    //                            if !(timerViewcontrollerObj?.isActivityPaused ?? false){
    //                                if #available(macOS 12.0, *) {
    //                                    if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
    //                                        timerViewcontrollerObj?.btnTabVideoClicked(self)
    //                                    }
    //                                    timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
    //                                } else {
    //                                    // Fallback on earlier versions
    //                                    timerViewcontrollerObj?.loadBlankUrl()
    //                                }
    //                            }
    //                        }
    //                    }
    //                }
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            if getsmallCountDownVcObject().timer != nil {
    //                                getsmallCountDownVcObject().timer?.invalidate()
    //                            }
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    //    @IBAction func btnAbortClicked(_ sender: Any) {
    //        addLog(text: "[user-action] button Abort Clicked")
    ////        abortCurrentState() //
    //    }
    
    //    func abortCurrentState(){// added on 10/4/25 in 1.21.356
    //        addLog(text: "func abortCurrentState")// added on 10/4/25 in 1.21.356
    //        if currentState == ._ASK_APP_WORK_ || currentState == ._BREATHING_{
    //            abortOnboardingWork()
    //            return;
    //        }
    //        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._START_ && firstViewControllerObj != nil && editHabitRoutineVcObj != nil{
    //            if firstViewControllerObj!.isViewLoaded{
    //                if containerView.subviews.contains(firstViewControllerObj!.view){
    //                    if firstViewControllerObj!.view.subviews.contains(editHabitRoutineVcObj!.view){
    //                        editHabitRoutineVcObj!.view.removeFromSuperview()
    //                        firstViewControllerObj!.btnEditHabits.isHidden = false
    //                        return;
    //                    }
    //                }
    //            }
    //        }
    //
    //        lastCurrentState = currentState
    //        lastCurrentAction = currentAction
    //        hideCloseButtons()
    //
    //        stopActivityCountDownTimer()
    //
    //        if currentState == ._MORNING_HABIT_{
    //
    //            refreshLastPostponeCount()
    //
    //            if SettingsManagerObject.isEasySkipEnabled{
    //
    //                if currentHabitPlaying != nil{
    //                    if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                        if smallCountDownWcObj?.window != nil{
    //                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                                getSmallCountDownWindowObject().window?.close()
    //                            }
    //                        }
    //                    }
    //                }
    //                //                mainWindowControllerObj?.window?.close() //
    //                //                hideBlankWindowInSecondaryMonitor() //
    //
    //                showEasyPostponeWindow()
    //                stopActivityTimer()
    //
    //                if currentHabitPlaying != nil{
    //                    closePupUpBlockIfVisible()
    //                }
    //
    //            }else{
    //                stopActivityTimer()
    //                if activityPostponeCount == 0{
    //                    showAskPostponeView()
    //                }else{
    //                    if shouldAskPassword(){
    //                        if SettingsManagerObject.isPasswordRequireInSkipMorning{
    //                            mainViewControllerObj?.showPasswordView()
    //                            enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
    //                        }else{
    //                            showAskPostponeView()
    //                        }
    //
    //                    }else{
    //                        showAskPostponeView()
    //                    }
    //
    //                }
    //            }
    //
    //        }else if currentState == ._EVENING_HABIT_{
    //            refreshLastPostponeCount()
    //
    //            if SettingsManagerObject.isEasySkipEnabled{
    //
    //                if currentHabitPlaying != nil{
    //                    if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                        if smallCountDownWcObj?.window != nil{
    //                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                                getSmallCountDownWindowObject().window?.close()
    //                            }
    //                        }
    //                    }
    //                }
    //
    ////                mainWindowControllerObj?.window?.close() //
    ////                hideBlankWindowInSecondaryMonitor() //
    //
    //                showEasyPostponeWindow()
    //                stopActivityTimer()
    //
    //                if currentHabitPlaying != nil{
    //                    closePupUpBlockIfVisible()
    //                }
    //
    //            }else{
    //                stopActivityTimer()
    //
    //                if activityPostponeCount == 0{
    //                    if isHighPrioritySequenceGoing{
    //                        if shouldAskPassword(){
    //                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
    //                                showPasswordView()
    //                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
    //                            }else{
    //                                showAskPostponeView()
    //                            }
    //                        }else{
    //                            showAskPostponeView()
    //                        }
    //                    }else{
    //                        showAskPostponeView()
    //                    }
    //                }else{
    //                    if shouldAskPassword(){
    //                        if isHighPrioritySequenceGoing{
    //                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
    //                                showPasswordView()
    //                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
    //                            }else{
    //                                showAskPostponeView()
    //                            }
    //                        }else{
    //                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
    //                                showPasswordView()
    //                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
    //                            }else{
    //                                showAskPostponeView()
    //                            }
    //                        }
    //                    }else{
    //                        showAskPostponeView()
    //                    }
    //                }
    //            }
    //        }else if currentState == ._MICRO_BREAK_{
    //            var lastSavedPostponeTime = Date()
    //            activityPostponeCount = 0
    //            var lastSavedPostponeCount = activityPostponeCount
    //            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //
    //            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakActivityPostponeInfo) as? [String:Any]{
    //                if let postponeCount =  infoDic["postponeCount"] as? Int{
    //                    lastSavedPostponeCount = postponeCount
    //                }
    //                if let date =  infoDic["date"] as? Date{
    //                    lastSavedPostponeTime = date
    //                }
    //            }
    //
    //            if lastSavedPostponeTime.compare(startDate) == .orderedDescending{
    //                    activityPostponeCount = lastSavedPostponeCount
    //            }
    //
    //            if SettingsManagerObject.isEasySkipEnabled{
    //                if currentAction == ._START_ || currentAction == ._BRAIN_DUMP_{
    //
    //                    if currentActivityPlaying != nil{
    //                        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                            if smallCountDownWcObj?.window != nil{
    //                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                                    getSmallCountDownWindowObject().window?.close()
    //                                }
    //                            }
    //                        }
    //                    }
    //                    mainWindowControllerObj?.window?.close()
    //                    hideBlankWindowInSecondaryMonitor()
    //                    showEasyPostponeWindow()
    //                    if currentActivityPlaying != nil{
    //                        closePupUpBlockIfVisible()
    //                    }
    //                }else{
    //                    postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil, isFromBreakWarningWindow:false)
    //                }
    //            }else{
    //                if currentAction == ._START_{// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
    //                    showAskPostponeView()
    //                }else{
    //                    showAskPostponeView()
    //                }
    //            }
    //
    //        }else if currentState == ._FOCUS_SUMMARY_{
    //            showAskPostponeView()
    //        }else if currentState == ._SPECIAL_ACTIVITY_{
    //            specialActivityFinish()
    //        }else if currentState == ._CUSTOM_ROUTINE_{
    //            if currentHabitPlaying != nil{
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //            }
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //
    //            showEasyPostponeWindow()
    //
    //            if currentHabitPlaying != nil{
    //                closePupUpBlockIfVisible()
    //            }
    //        }
    //    }
    //    func processAborting(){
    //        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
    //            if shouldAskPassword(){
    //                if activityPostponeCount == 0{//it  means we did not ask for password when user clicked on please apare me button so need to ask now
    //                    if currentState == ._MORNING_HABIT_{
    //                        if SettingsManagerObject.isPasswordRequireInSkipMorning{
    //                            showPasswordView()
    //                        }else{
    //                            showAbortStartView()
    //                        }
    //                    }else if currentState == ._EVENING_HABIT_{
    //
    //                        if isHighPrioritySequenceGoing{
    //                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
    //                                showPasswordView()
    //                            }else{
    //                                showAbortStartView()
    //                            }
    //                        }else{
    //                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
    //                                showPasswordView()
    //                            }else{
    //                                showAbortStartView()
    //                            }
    //                        }
    //                    }
    //                }else{
    //                    showAbortStartView()
    //                }
    //            }else{
    //                showAbortStartView()
    //            }
    //
    //        }else{
    //            showAbortStartView()
    //        }
    //    }
    
    func showPasswordView(){
        self.view.addSubview(enterPasswordVcObj!.view)
        self.view.addConstraints(subView: enterPasswordVcObj!.view)
        enterPasswordVcObj?.removeConstraints()
        enterPasswordVcObj?.parentVc = nil
        addLog(text: "Showing enter password view")
    }
    
    //    func showAbortStartView(){
    //        addLog(text: "showAbortStartView")
    //        removeSubViews()
    //        containerView.addSubview(abortingCountDownVcObj!.view)
    //        containerView.addConstraints(subView: abortingCountDownVcObj!.view)
    //        abortingCountDownVcObj?.startTimer()
    //        currentState = ._ABORT_
    //    }
    
    //    func abortCancel(){
    //        addLog(text: "abortCancel")
    //
    //        if lastCurrentState == ._MICRO_BREAK_{
    //            self.showCloseButtons()
    //            removeSubViews()
    //            switch lastCurrentAction {
    //            case ._START_:
    //                currentState = ._MICRO_BREAK_
    //                currentAction = ._START_
    //                thirdVcObj?.startBreakActivity()
    //                firstViewControllerObj?.isFirstTime = false
    //
    //                containerView.addSubview(firstViewControllerObj!.view)
    //                containerView.addConstraints(subView: firstViewControllerObj!.view)
    //                firstViewControllerObj?.tblViewHabits.reloadData()
    //                break
    //            case ._INPROGRESS_:
    //                containerView.addSubview(timerViewcontrollerObj!.view)
    //                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //
    //                timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: timerViewcontrollerObj?.currentDurationInSeconds ?? 0, name: timerViewcontrollerObj?.currentActicityTitle ?? "", url: timerViewcontrollerObj?.currentUrl, useTimer:timerViewcontrollerObj?.currentActivityUseTimer ?? true)
    //                currentState = ._MICRO_BREAK_
    //                currentAction = ._INPROGRESS_
    //                break
    //            case ._END_:
    //                self.showCloseButtons()
    //                removeSubViews()
    //                containerView.addSubview(thirdVcObj!.view)
    //                containerView.addConstraints(subView: thirdVcObj!.view)
    //                currentState = ._MICRO_BREAK_
    //                currentAction = ._END_
    //                break
    //            case ._VISUALIZE_:
    //                break
    //            case ._BRAIN_DUMP_:
    //                currentState = ._MICRO_BREAK_
    //                currentAction = ._BRAIN_DUMP_
    //
    //                thirdVcObj?.startBreakActivity()
    //                showBreaksBrainDump()
    //
    //                break
    //            }
    //        }else if lastCurrentState == ._MORNING_HABIT_{
    //            self.showCloseButtons()
    //            removeSubViews()
    //            switch lastCurrentAction {
    //            case ._START_:
    //                showAllMorningHabitsAbortCancel()
    //            case ._INPROGRESS_:
    //                containerView.addSubview(timerViewcontrollerObj!.view)
    //                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, url: arrFilteredMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrFilteredMorningHabits[currentHabitIndex].name!, useTimer: arrFilteredMorningHabits[currentHabitIndex].useTimer)
    //                currentState = ._MORNING_HABIT_
    //                currentAction = ._INPROGRESS_
    //                break
    //            case ._END_:
    //                self.showCloseButtons()
    //                removeSubViews()
    //                containerView.addSubview(thirdVcObj!.view)
    //                containerView.addConstraints(subView: thirdVcObj!.view)
    //                currentState = ._MORNING_HABIT_
    //                currentAction = ._END_
    //                break
    //            case ._VISUALIZE_:
    //                currentState = ._MORNING_HABIT_
    //                mainViewControllerObj?.showVisualizeInstructionsVc()
    //                break
    //            case ._BRAIN_DUMP_:
    //                break
    //            }
    //
    //        }else if lastCurrentState == ._EVENING_HABIT_{
    //            self.showCloseButtons()
    //            removeSubViews()
    //            switch lastCurrentAction {
    //            case ._START_:
    //                showAllEveningHabitsAbortCancel()
    //            case ._INPROGRESS_:
    //                containerView.addSubview(timerViewcontrollerObj!.view)
    //                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, url: arrFilteredEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrFilteredEveningHabits[currentHabitIndex].name!, useTimer: arrFilteredEveningHabits[currentHabitIndex].useTimer)
    //                currentState = ._EVENING_HABIT_
    //                currentAction = ._INPROGRESS_
    //                break
    //            case ._END_:
    //                self.showCloseButtons()
    //                removeSubViews()
    //                containerView.addSubview(thirdVcObj!.view)
    //                containerView.addConstraints(subView: thirdVcObj!.view)
    //                currentState = ._EVENING_HABIT_
    //                currentAction = ._END_
    //                break
    //            case ._VISUALIZE_:
    //                currentState = ._EVENING_HABIT_
    //                mainViewControllerObj?.showVisualizeInstructionsVc()
    //                break
    //            case ._BRAIN_DUMP_:
    //                break
    //            }
    //
    //        }else if lastCurrentState == ._SHUTOFFMAC_{
    //            self.showCloseButtons()
    //            removeSubViews()
    ////            shutOffMac()
    //        }else if lastCurrentState == ._FOCUS_SUMMARY_{
    //            mainWindowControllerObj?.showWindow(self)
    //            showBlankWindowInSecondaryMonitor()
    //            self.hideCloseButtons()
    //            self.removeSubViews()
    //            self.containerView.addSubview(focusSummaryVcObj!.view)
    //            self.containerView.addConstraints(subView: focusSummaryVcObj!.view)
    //            currentState = ._FOCUS_SUMMARY_
    //        }else if lastCurrentState == ._CUSTOM_ROUTINE_{
    //            self.showCloseButtons()
    //            removeSubViews()
    //            switch lastCurrentAction {
    //            case ._START_:
    //                showAllCustomRoutineHabitsAbortCancel()
    //            case ._INPROGRESS_:
    //                containerView.addSubview(timerViewcontrollerObj!.view)
    //                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //                let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
    //                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, url: arrHabits[currentHabitIndex].urlsArray.randomElement(), name: arrHabits[currentHabitIndex].name!, useTimer: arrHabits[currentHabitIndex].useTimer)
    //                currentState = ._CUSTOM_ROUTINE_
    //                currentAction = ._INPROGRESS_
    //                break
    //            case ._END_:
    //                self.showCloseButtons()
    //                removeSubViews()
    //                containerView.addSubview(thirdVcObj!.view)
    //                containerView.addConstraints(subView: thirdVcObj!.view)
    //                currentState = ._CUSTOM_ROUTINE_
    //                currentAction = ._END_
    //                break
    //            case ._VISUALIZE_:
    //                currentState = ._CUSTOM_ROUTINE_
    //                mainViewControllerObj?.showVisualizeInstructionsVc()
    //                break
    //            case ._BRAIN_DUMP_:
    //                break
    //            }
    //        }
    //
    //    }
    
    
    //    func showAbortConfirmationView(){
    //        addLog(text: "showAbortConfirmationView")
    //        hideCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(abortingConfirmVcObj!.view)
    //        containerView.addConstraints(subView: abortingConfirmVcObj!.view)
    //        abortingConfirmVcObj!.resetData()
    //        currentState = ._ABORT_
    //        activityPostponeCount = 0
    //    }
    //    func showAbortStartSmallVc(isAnyHabitRemoved:Bool){
    //        addLog(text: "showAbortStartSmallVc")
    //        hideCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(abortingCantHandleVcObj!.view)
    //        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
    //        abortingCantHandleVcObj!.isViewStartingSmall = true
    //        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: isAnyHabitRemoved)
    //        currentState = ._ABORT_
    //    }
    //    func showAbortDisableMorningRoutineVc(){
    //        addLog(text: "showAbortDisableMorningRoutineVc")
    //        hideCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(abortingCantHandleVcObj!.view)
    //        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
    //        abortingCantHandleVcObj!.isViewStartingSmall = false
    //        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: false)
    //        currentState = ._ABORT_
    //    }
    //    func showAbortDoneView(){
    //        addLog(text: "showAbortDoneView")
    //        hideCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(abortDoneVcObj!.view)
    //        containerView.addConstraints(subView: abortDoneVcObj!.view)
    //        abortDoneVcObj?.startTimer()
    //        currentState = ._ABORT_
    //    }
    func disableApp(){
        addLog(text: "App Deactivated by user (Aborted)")
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsAppEnabled)
        SettingsManagerObject.disableAppWriteSettings()
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
    
    //    func shutOffMac(){
    //        isHabitAlreadyShowed = false
    //        if currentState == ._SHUTOFFMAC_{
    //            return;
    //        }
    //        addLog(text: "Showing Shut Off screen.")
    //        hideCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(shutOffTimeVcObj!.view)
    //        containerView.addConstraints(subView: shutOffTimeVcObj!.view)
    //        currentState = ._SHUTOFFMAC_
    //        stopActivityTimer()
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    //    func showFirstTimeVc(){
    //        addLog(text: "Showing first time welcome activity.")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        firstViewControllerObj?.isFirstTime = true//ik bar object bna or dusri line mai true hua debug mode mai qki debug mode mai sare global variables ya obj call krne k baad initialize hote hai
    //        firstViewControllerObj?.isFirstTime = true
    //        containerView.addSubview(firstViewControllerObj!.view)
    //        containerView.addConstraints(subView: firstViewControllerObj!.view)
    //        currentState = ._BREATHING_
    //        currentAction = ._START_
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    
    func showAskAppWorkVc(){
        addLog(text: "Showing Ask App Work view.")
        removeSubViews()
        
        containerView.addSubview(getAskAppWorkVcObject().view)
        containerView.addConstraints(subView: getAskAppWorkVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showAchieveWithFocusBearVc(){
        addLog(text: "Showing Achieve With Focus Bear view.")
        allApiObject.capturePosthog(event: "what-to-achieve-with-focus-bear-screen-shown", metadata: [:])
        removeSubViews()
        
        containerView.addSubview(getAchieveWithFocusBearVcObject().view)
        containerView.addConstraints(subView: getAchieveWithFocusBearVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showAskOccupationVc(){
        addLog(text: "Showing Ask App Work view.")
        removeSubViews()
        
        containerView.addSubview(getAskOccupationVcObject().view)
        containerView.addConstraints(subView: getAskOccupationVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showInstalltHabitPacksVc(){
        addLog(text: "Showing install Habit Packs view.")
        removeSubViews()
        
        containerView.addSubview(getInstallHabitPacksVcObj().view)
        containerView.addConstraints(subView: getInstallHabitPacksVcObj().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
        allApiObject.capturePosthog(event: "habit-packs-shown", metadata: [:])
    }
    
    func showAdditionalGoalsVc(){
        addLog(text: "Showing Additional Goals view.")
        removeSubViews()
        
        containerView.addSubview(getAdditionalGoalsVcObject().view)
        containerView.addConstraints(subView: getAdditionalGoalsVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showOnboardingFocusExplainVc(){
        addLog(text: "Showing Onboarding Focus Explain view.")
        allApiObject.capturePosthog(event: "focus-explain-screen-shown", metadata: [:])
        removeSubViews()
        
        containerView.addSubview(getOnboardingFocusExplainVcObject().view)
        containerView.addConstraints(subView: getOnboardingFocusExplainVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showOnboardingHabitExplainVc(){
        addLog(text: "Showing Onboarding Habit Explain view.")
        allApiObject.capturePosthog(event: "routine-explain-screen-shown", metadata: [:])
        removeSubViews()
        
        containerView.addSubview(getOnboardingHabitExplainVcObject().view)
        containerView.addConstraints(subView: getOnboardingHabitExplainVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    func showSelectHabitsLaterInfoVc(){
        addLog(text: "Showing Additional Goals view.")
        removeSubViews()
        
        containerView.addSubview(getSelectHabitsLaterInfoVcObject().view)
        containerView.addConstraints(subView: getSelectHabitsLaterInfoVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showAskWorkTimeVc(){
        addLog(text: "Showing Ask Work Time view.")
        removeSubViews()
        
        containerView.addSubview(getAskWorkTimeVcObject().view)
        containerView.addConstraints(subView: getAskWorkTimeVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showConfirmMorningRoutineTimeVc(){
        addLog(text: "Showing Confirm Morning Routine Time view.")
        removeSubViews()
        
        containerView.addSubview(getConfirmMorningRoutineTimeVcObject().view)
        containerView.addConstraints(subView: getConfirmMorningRoutineTimeVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showConfirmEveningRoutineTimeVc(){
        addLog(text: "Showing Confirm Evening Routine Time view.")
        removeSubViews()
        
        containerView.addSubview(getConfirmEveningRoutineTimeVcObject().view)
        containerView.addConstraints(subView: getConfirmEveningRoutineTimeVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showAskBreakTimeVc(){
        addLog(text: "Showing Ask Break Time view.")
        removeSubViews()
        
        containerView.addSubview(getaskBreakTimeVcObject().view)
        containerView.addConstraints(subView: getaskBreakTimeVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showTakeBreaksInfoVc(){
        addLog(text: "Showing Take Breaks Info view.")
        removeSubViews()
        
        containerView.addSubview(geTakeBreaksInfoVcObject().view)
        containerView.addConstraints(subView: geTakeBreaksInfoVcObject().view)
        currentState = ._ASK_APP_WORK_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    //    func showVisualizeInstructionsVc(){
    //        addLog(text: "show Visualize Instructions Vc.")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentAction = ._VISUALIZE_
    //        containerView.addSubview(getvisualizeInstructionsObject().view)
    //        containerView.addConstraints(subView: getvisualizeInstructionsObject().view)
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    //
    //    func showBreaksBrainDump(){
    //        allApiObject.capturePosthog(event: "breaks-brain-dump-shown", metadata: [:])
    //        addLog(text: "show Breaks Brain Dump.")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentAction = ._BRAIN_DUMP_
    //        containerView.addSubview(getBreaksBrainDumpVcObject().view)
    //        containerView.addConstraints(subView: getBreaksBrainDumpVcObject().view)
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    
    
    
    //    func showAllEveningHabits(){
    //        addLog(text: "func showAllEveningHabits:- Initiate and run Evening Habits.")
    //
    //
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //
    //        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
    //            currentState = ._EVENING_HABIT_
    //            showVisualizeInstructionsVc()
    //            addLog(text: "func showAllEveningHabits:- current action is visualize:- return")
    //            return;
    //        }
    //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitID)
    //
    //        var lastSavedActivityTime = Date()
    //        var lastSavedActivityProgress = 0
    //        var lastSavedActivityId = ""
    //        var lastActivityIndex = -1
    //        if isHighPrioritySequenceGoing{
    //            if !arrFilteredEveningHabits[0].isPriorityHigh{
    ////                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
    //                isLastActivityStoppedInRunningState = false
    //            }
    //        }
    //
    //        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
    //            if let id =  infoDic["id"] as? String{
    //                lastSavedActivityId = id
    //            }
    //            if let duration =  infoDic["duration"] as? Int{
    //                lastSavedActivityProgress = duration
    //            }
    //            if let date =  infoDic["date"] as? Date{
    //                lastSavedActivityTime = date
    //                for i in 0..<arrFilteredEveningHabits.count{
    //                    if arrFilteredEveningHabits[i].id == lastSavedActivityId{
    //                        lastActivityIndex = i
    //                        if isHighPrioritySequenceGoing{
    //                            if !arrFilteredEveningHabits[lastActivityIndex].isPriorityHigh{
    //                                lastActivityIndex = -1
    //                            }
    //                        }
    //                        break;
    //                    }
    //                }
    //            }else{
    //                lastSavedActivityId = ""
    //                lastSavedActivityProgress = 0
    //            }
    //        }
    //        let currentDate = Date()
    //        var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: currentDate)!
    //        if currentDate < shutOffdate{// iska matlab 20-24 k bich
    //            let tomorrowDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    //            shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: tomorrowDate) ?? tomorrowDate
    //
    //        }
    //        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredEveningHabits[0].id{
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func showAllEveningHabits:- Activity Postpone In Running State:- start direct \(arrFilteredEveningHabits[0].name ?? "") in running state")
    //            removeSubViews()
    //            self.showCloseButtons()
    //
    //            currentHabitIndex = 0
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._EVENING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
    //        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastActivityIndex != -1{
    //            if lastActivityIndex != -1{//user can start random habit
    //                let habit = arrFilteredEveningHabits[lastActivityIndex]
    //                arrFilteredEveningHabits.remove(at: lastActivityIndex)
    //                arrFilteredEveningHabits.insert(habit, at: 0)
    //            }
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func showAllEveningHabits:- app terminate In Running State:- start direct \(arrFilteredEveningHabits[0].name ?? "") in running state")
    //            removeSubViews()
    //            self.showCloseButtons()
    //            currentHabitIndex = 0
    //            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._EVENING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //        }else{
    //            addLog(text:"func showAllEveningHabits:- show All Evening Habits")
    //            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
    //            isLastActivityStoppedInRunningState = false
    //            isPromptToRememberHabitShowedInLastHabit = false
    //            self.showCloseButtons()
    //            removeSubViews()
    //
    //            if isHighPrioritySequenceGoing{
    //                for i in 0..<arrFilteredEveningHabits.count{
    //                    if arrFilteredEveningHabits[i].isPriorityHigh{
    //                        currentHabitIndex = i - 1
    //                        break;
    //                    }
    //                }
    //            }else{
    //                currentHabitIndex = -1
    //            }
    //
    //
    //            currentState = ._EVENING_HABIT_
    //            currentAction = ._START_
    //            firstViewControllerObj?.isFirstTime = false
    //            containerView.addSubview(firstViewControllerObj!.view)
    //            containerView.addConstraints(subView: firstViewControllerObj!.view)
    //            NSApplication.shared.activate(ignoringOtherApps: true)
    //            playStartMorningEveningRoutineSound()
    //        }
    //    }
    
    //    func showAllEveningHabitsAbortCancel(){
    //        addLog(text: "Abort Cancel:-Initiate and run Evening Habits.")
    //        isPromptToRememberHabitShowedInLastHabit = false
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentState = ._EVENING_HABIT_
    //        currentAction = ._START_
    //        firstViewControllerObj?.isFirstTime = false
    //        containerView.addSubview(firstViewControllerObj!.view)
    //        containerView.addConstraints(subView: firstViewControllerObj!.view)
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    //    func showAllMorningHabits(){
    //        addLog(text: "func showAllMorningHabits:- Showing morning habits.")
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
    //
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
    //            currentState = ._MORNING_HABIT_
    //            showVisualizeInstructionsVc()
    //            addLog(text: "func showAllMorningHabits:- current action is visualize:- return")
    //            return;
    //        }
    //
    //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitID)
    //        var lastSavedActivityTime = Date()
    //        var lastSavedActivityProgress = 0
    //        var lastSavedActivityId = ""
    //        var lastActivityIndex = -1
    //        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
    //
    //            if let id =  infoDic["id"] as? String{
    //                lastSavedActivityId = id
    //            }
    //            if let duration =  infoDic["duration"] as? Int{
    //                lastSavedActivityProgress = duration
    //            }
    //            if let date =  infoDic["date"] as? Date{
    //                lastSavedActivityTime = date
    //                for i in 0..<arrFilteredMorningHabits.count{
    //                    if arrFilteredMorningHabits[i].id == lastSavedActivityId{
    //                        lastActivityIndex = i
    //                        break;
    //                    }
    //                }
    //            }else{
    //                lastSavedActivityId = ""
    //                lastSavedActivityProgress = 0
    //            }
    //        }
    //        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
    //            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
    //        }
    //        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredMorningHabits[0].id{
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func showAllMorningHabits:- Activity Postpone In Running State:- start direct \(arrFilteredMorningHabits[0].name ?? "") in running state")
    //            removeSubViews()
    //            self.showCloseButtons()
    //
    //            currentHabitIndex = 0
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._MORNING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
    //
    //        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastActivityIndex != -1{
    //            if lastActivityIndex != -1{//user can start random habit
    //                let habit = arrFilteredMorningHabits[lastActivityIndex]
    //                arrFilteredMorningHabits.remove(at: lastActivityIndex)
    //                arrFilteredMorningHabits.insert(habit, at: 0)
    //            }
    //
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func showAllMorningHabits:- app terminate In Running State:- start direct \(arrFilteredMorningHabits[0].name ?? "") in running state")
    //            removeSubViews()
    //            self.showCloseButtons()
    //            currentHabitIndex = 0
    //            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._MORNING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //        }else{
    //            addLog(text:"func showAllMorningHabits:- show All Morning Habits")
    //            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
    //            isLastActivityStoppedInRunningState = false
    //            isPromptToRememberHabitShowedInLastHabit = false
    //            lastShownRandomChoiceDic = [String:activityChoice]()
    //            self.showCloseButtons()
    //            removeSubViews()
    //            currentHabitIndex = -1
    //            currentState = ._MORNING_HABIT_
    //            currentAction = ._START_
    //            firstViewControllerObj?.isFirstTime = false
    //            containerView.addSubview(firstViewControllerObj!.view)
    //            containerView.addConstraints(subView: firstViewControllerObj!.view)
    //            firstViewControllerObj?.checkMorningHabitDelayTime()
    //            NSApplication.shared.activate(ignoringOtherApps: true)
    //            playStartMorningEveningRoutineSound()
    //            getTotalFocuedTime()
    //        }
    //    }
    //    func showAllMorningHabitsAbortCancel(){
    //        addLog(text: "Abort Cancel Showing morning habits.")
    //        isPromptToRememberHabitShowedInLastHabit = false
    //        lastShownRandomChoiceDic = [String:activityChoice]()
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentState = ._MORNING_HABIT_
    //        currentAction = ._START_
    //        firstViewControllerObj?.isFirstTime = false
    //        containerView.addSubview(firstViewControllerObj!.view)
    //        containerView.addConstraints(subView: firstViewControllerObj!.view)
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    //    func showAllCustomRoutineHabitsAbortCancel(){
    //        addLog(text: "Abort Cancel Showing Custom Routine habits.")
    //        isPromptToRememberHabitShowedInLastHabit = false
    //        lastShownRandomChoiceDic = [String:activityChoice]()
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentState = ._CUSTOM_ROUTINE_
    //        currentAction = ._START_
    //        firstViewControllerObj?.isFirstTime = false
    //        containerView.addSubview(firstViewControllerObj!.view)
    //        containerView.addConstraints(subView: firstViewControllerObj!.view)
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    //
    //    func startFirstMorningHabit() {
    //        addLog(text:"current startFirstMorningHabit called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex = 0
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:0)
    //        currentState = ._MORNING_HABIT_
    //        currentAction = ._INPROGRESS_
    //        allApiObject.capturePosthog(event: "start-morning-routine", metadata: ["routine-type":"morning_routine"])
    //    }
    //
    //    func startFirstEveningHabit() {
    //        addLog(text:"current startFirstEveningHabit called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
    //
    //        if isHighPrioritySequenceGoing{
    //            for i in 0..<arrFilteredEveningHabits.count{
    //                if arrFilteredEveningHabits[i].isPriorityHigh{
    //                    if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
    //                        let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
    //                        let currentDate = Date()
    //                        if currentDate > cutOffDate{
    //                            addLog(text: "evening habit skipped:- cutoff time for this first habit passed:- \(arrFilteredEveningHabits[i].name)  \(arrFilteredEveningHabits[i].id)") // remove this
    //                            continue;
    //                        }
    //                    }
    //                    currentHabitIndex = i
    //                    break;
    //                }
    //            }
    //        }else{
    //            currentHabitIndex = 0
    //        }
    //
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:0)
    //        currentState = ._EVENING_HABIT_
    //        currentAction = ._INPROGRESS_
    //        allApiObject.capturePosthog(event: "start-evening-routine", metadata: ["routine-type":"evening_routine"])
    //    }
    //
    //    func startFirstCustomRoutineHabit() {
    //        addLog(text:"current startFirstCustomRoutineHabit called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex = 0
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
    //        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:0)
    //        currentState = ._CUSTOM_ROUTINE_
    //        currentAction = ._INPROGRESS_
    //        allApiObject.capturePosthog(event: "start-custom-routine", metadata: ["routine-type":"custom_routine"])
    //    }
    
    
    func startBreathing() {
        addLog(text:"current startBreathing called")
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
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.breathingFinished(isSKipped: isSKipped)
        currentState = ._BREATHING_
        currentAction = ._END_
        allApiObject.capturePosthog(event: "complete-first-routine", metadata: ["routine-type":"first_routine"])
    }
    
    //    func morningHabitOver() {
    //        addLog(text:"current morning Habit Over called")
    //        getHabitsVcObject().stopActivityTimer()
    //        if mainWindowControllerObj?.window?.isVisible == false{
    //            mainWindowControllerObj?.window?.setIsVisible(true)
    //            showBlankWindowInSecondaryMonitor()
    //            setDocBarTo(isHide: false)
    //        }
    //        addLog(text:"setDocBarTo passed")
    //        if isAnyAllowedFocusModeActivityRunning{
    //            closeNudgeFocusAlignmentScoreWindow()
    //        }
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //        if taskPlayerWcObj != nil{
    //            if taskPlayerWcObj?.window?.isVisible ?? false{
    //                taskPlayerVcObj?.getToDosFromPlayer()
    //                taskPlayerWcObj?.window?.close()
    //                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
    //            }
    //        }
    //        addLog(text:"toolBoxWinow close passed")
    //        refreshFocusModeData()
    //        setAppIconForFocusModeScore(probability: nil)
    //
    //        closePupUpBlockIfVisible()
    //        addLog(text:"closePupUpBlockIfVisible passed")
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        addLog(text:"showCloseButtons passed")
    //        removeSubViews()
    //        addLog(text:"removeSubViews passed")
    //        containerView.addSubview(thirdVcObj!.view)
    //        containerView.addConstraints(subView: thirdVcObj!.view)
    //        thirdVcObj!.morningHabitFinished(index: currentHabitIndex)
    //        addLog(text:"morningHabitFinished passed")
    //        currentState = ._MORNING_HABIT_
    //        currentAction = ._END_
    //        if activityPostponeCount > 3{
    //            activityPostponeCount = 3//I complete a habit after postponing, it should go back to a 15 second postpone the next time
    //            savePostpneCount(state: ._MORNING_HABIT_)
    //        }
    //        addLog(text:"savePostpneCount passed")
    //    }
    
    //    func startDirectIncompleteMorningHabitAtIndex(index:Int, isLastActivitySkipped:Bool) {
    //        addLog(text:"func:- startDirectIncompleteMorningHabitAtIndex")
    //        currentState = ._MORNING_HABIT_// changing state here because in load completed habit graph there is a check about current state
    //        currentAction = ._END_
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //
    //        refreshFocusModeData()
    //
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
    //
    //        var lastSavedActivityTime = Date()
    //        var lastSavedActivityProgress = 0
    //        var lastSavedActivityId = ""
    //        var lastActivityIndex = -1
    //
    //        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
    //
    //            if let id =  infoDic["id"] as? String{
    //                lastSavedActivityId = id
    //            }
    //            if let duration =  infoDic["duration"] as? Int{
    //                lastSavedActivityProgress = duration
    //            }
    //            if let date =  infoDic["date"] as? Date{
    //                lastSavedActivityTime = date
    //                for i in 0..<arrFilteredMorningHabits.count{
    //                    if arrFilteredMorningHabits[i].id == lastSavedActivityId{
    //                        lastActivityIndex = i
    //                        break;
    //                    }
    //                }
    //            }else{
    //                lastSavedActivityId = ""
    //                lastSavedActivityProgress = 0
    //            }
    //        }
    //        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
    //            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
    //        }
    //        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredMorningHabits[index].id{
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- Activity Postpone In Running State:- start direct \(arrFilteredMorningHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._MORNING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
    //
    //
    //        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrFilteredMorningHabits[index].id{
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredMorningHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._MORNING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //
    //        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastActivityIndex != -1 && lastActivityIndex > index{//user can start random habit
    //
    //            if lastActivityIndex != -1{//user can start random habit
    //                let habit = arrFilteredMorningHabits[lastActivityIndex]
    //                arrFilteredMorningHabits.remove(at: lastActivityIndex)
    //                arrFilteredMorningHabits.insert(habit, at: index)
    //            }
    //
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredMorningHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._MORNING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //
    //        }else{
    //            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- morningHabitFinishedAndStartIncompleteNew")
    //            isLastActivityStoppedInRunningState = false
    //
    //            if index == 0{
    //                showAllMorningHabits()
    //            }else{
    //                containerView.addSubview(thirdVcObj!.view)
    //                containerView.addConstraints(subView: thirdVcObj!.view)
    //                currentHabitIndex = index-1
    //                thirdVcObj!.morningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
    //            }
    //
    //        }
    //
    //    }
    
    //    func showRoutineAllHabits(routineIndex:Int){
    //        addLog(text: "func showRoutineAllHabits:- Showing Routine habits.")
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
    //
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
    //            currentState = ._CUSTOM_ROUTINE_
    //            showVisualizeInstructionsVc()
    //            addLog(text: "func showRoutineAllHabits:- current action is visualize:- return")
    //            return;
    //        }
    //
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex = -1
    //        currentState = ._CUSTOM_ROUTINE_
    //        currentAction = ._START_
    //        firstViewControllerObj?.isFirstTime = false
    //        containerView.addSubview(firstViewControllerObj!.view)
    //        containerView.addConstraints(subView: firstViewControllerObj!.view)
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //        playStartMorningEveningRoutineSound()
    //        getTotalFocuedTime()
    //    }
    
    //    func startDirectIncompleteCustomRoutineHabitAtIndex(index:Int, isLastActivitySkipped:Bool) {
    //        addLog(text:"func:- startDirectIncompleteCustomRoutineHabitAtIndex")
    //        currentState = ._CUSTOM_ROUTINE_// changing state here because in load completed habit graph there is a check about current state
    //        currentAction = ._END_
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //
    //        refreshFocusModeData()
    //
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //
    //        var lastSavedActivityTime = Date()
    //        var lastSavedActivityProgress = 0
    //        var lastSavedActivityId = ""
    //        var lastActivityIndex = -1
    //
    //        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastCustomRoutineHabitRunningInfo) as? [String:Any]{
    //
    //            if let id =  infoDic["id"] as? String{
    //                lastSavedActivityId = id
    //            }
    //            if let duration =  infoDic["duration"] as? Int{
    //                lastSavedActivityProgress = duration
    //            }
    //            if let date =  infoDic["date"] as? Date{
    //                lastSavedActivityTime = date
    //                for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
    //                    if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id == lastSavedActivityId{
    //                        lastActivityIndex = i
    //                        break;
    //                    }
    //                }
    //            }else{
    //                lastSavedActivityId = ""
    //                lastSavedActivityProgress = 0
    //            }
    //        }
    //
    //        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
    //            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
    //        }
    //
    //        if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[index].id{
    //            addLog(text:"func startDirectIncompleteCustomRoutineHabitAtIndex:- app terminate In Running State:- start direct \(arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            if lastSavedActivityProgress > arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._CUSTOM_ROUTINE_
    //            currentAction = ._INPROGRESS_
    //            let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //
    //        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastActivityIndex != -1 && lastActivityIndex > index{//user can start random habit
    //
    //
    //            if lastActivityIndex != -1{//user can start random habit
    //                let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[lastActivityIndex]
    //                arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: lastActivityIndex)
    //                arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: index)
    //            }
    //            var arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
    //            addLog(text:"func startDirectIncompleteCustomRoutineHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredMorningHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            if lastSavedActivityProgress > arrHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._CUSTOM_ROUTINE_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //
    //        }else{
    //            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- morningHabitFinishedAndStartIncompleteNew")
    //            if index == 0{
    //                showRoutineAllHabits(routineIndex: currentRoutineIndex)
    //            }else{
    //                containerView.addSubview(thirdVcObj!.view)
    //                containerView.addConstraints(subView: thirdVcObj!.view)
    //                currentHabitIndex = index-1
    //                thirdVcObj!.customRoutineHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
    //            }
    //
    //        }
    //
    //    }
    
    //    func showThirdVc(){
    //        removeSubViews()
    //        containerView.addSubview(thirdVcObj!.view)
    //        containerView.addConstraints(subView: thirdVcObj!.view)
    //    }
    
    //    func eveningHabitOver() {// current evening habit over
    //        addLog(text:"current evening Habit Over called")
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
    //        getHabitsVcObject().stopActivityTimer()
    //        if mainWindowControllerObj?.window?.isVisible == false{
    //            mainWindowControllerObj?.window?.setIsVisible(true)
    //            showBlankWindowInSecondaryMonitor()
    //            setDocBarTo(isHide: false)
    //        }
    //        if isAnyAllowedFocusModeActivityRunning{
    //            closeNudgeFocusAlignmentScoreWindow()
    //        }
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //        currentRelaxHabitPlaying = nil
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //        if taskPlayerWcObj != nil{
    //            if taskPlayerWcObj?.window?.isVisible ?? false{
    //                taskPlayerVcObj?.getToDosFromPlayer()
    //                taskPlayerWcObj?.window?.close()
    //                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
    //            }
    //        }
    //        refreshFocusModeData()
    //        setAppIconForFocusModeScore(probability: nil)
    //
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //        //        if currentHabitIndex < arrFilteredEveningHabits.count-1 {
    //        containerView.addSubview(thirdVcObj!.view)
    //        containerView.addConstraints(subView: thirdVcObj!.view)
    //        thirdVcObj!.eveningHabitFinished(index: currentHabitIndex)
    //        currentState = ._EVENING_HABIT_
    //        currentAction = ._END_
    //
    //        if activityPostponeCount > 3{
    //            activityPostponeCount = 3//I complete a habit after postponing, it should go back to a 15 second postpone the next time
    //            savePostpneCount(state: ._EVENING_HABIT_)
    //        }
    //    }
    
    //    func startDirectIncompleteEveningHabitAtIndex(index:Int, isLastActivitySkipped:Bool, skippedActivities:[String], completedActivities:[String]) {
    //        addLog(text:"func startDirectIncompleteEveningHabitAtIndex")
    //        currentState = ._EVENING_HABIT_
    //        currentAction = ._END_
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //
    //        refreshFocusModeData()
    //
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //
    //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
    //
    //        var lastSavedActivityTime = Date()
    //        var lastSavedActivityProgress = 0
    //        var lastSavedActivityId = ""
    //        var lastActivityIndex = -1
    //
    //        if isHighPrioritySequenceGoing{
    //            if !arrFilteredEveningHabits[index].isPriorityHigh{
    //                isLastActivityStoppedInRunningState = false
    //            }
    //        }
    //        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
    //
    //            if let id =  infoDic["id"] as? String{
    //                lastSavedActivityId = id
    //            }
    //            if let duration =  infoDic["duration"] as? Int{
    //                lastSavedActivityProgress = duration
    //            }
    //            if let date =  infoDic["date"] as? Date{
    //                lastSavedActivityTime = date
    //                for i in 0..<arrFilteredEveningHabits.count{
    //                    if arrFilteredEveningHabits[i].id == lastSavedActivityId{
    //                        lastActivityIndex = i
    //                        if isHighPrioritySequenceGoing{
    //                            if !arrFilteredEveningHabits[lastActivityIndex].isPriorityHigh{
    //                                lastActivityIndex = -1
    //                            }
    //                            if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
    //                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
    //                                let currentDate = Date()
    //                                if currentDate > cutOffDate{
    //                                    addLog(text: "evening habit skipped:- cutoff time for this incomplete habit passed:- \(arrFilteredEveningHabits[i].name ?? "")  \(arrFilteredEveningHabits[i].id ?? "")") // remove this
    //                                    lastActivityIndex = -1
    //                                }
    //                            }
    //                        }
    //
    //
    //                        break;
    //                    }
    //                }
    //            }else{
    //                lastSavedActivityId = ""
    //                lastSavedActivityProgress = 0
    //            }
    //        }
    //        let currentDate = Date()
    //        var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: currentDate)!
    //        if currentDate < shutOffdate{// iska matlab 20-24 k bich
    //            let tomorrowDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    //            shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: tomorrowDate) ?? tomorrowDate
    //
    //        }
    //
    //        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredEveningHabits[index].id{
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- Activity Postpone In Running State:- start direct\(arrFilteredEveningHabits[index].name ?? "")in running state")
    //
    //            currentHabitIndex = index
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._EVENING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
    //        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastSavedActivityId == arrFilteredEveningHabits[index].id{
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredEveningHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._EVENING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //
    //        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastActivityIndex != -1 && lastActivityIndex > index{
    //
    //            if lastActivityIndex != -1{//user can start random habit
    //                let habit = arrFilteredEveningHabits[lastActivityIndex]
    //                arrFilteredEveningHabits.remove(at: lastActivityIndex)
    //                arrFilteredEveningHabits.insert(habit, at: index)
    //            }
    //
    //            isLastActivityStoppedInRunningState = false
    //            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- app terminate In Running State:- start direct \(arrFilteredEveningHabits[index].name ?? "") in running state")
    //
    //            currentHabitIndex = index
    //            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
    //                lastSavedActivityProgress = 0
    //            }
    //            containerView.addSubview(timerViewcontrollerObj!.view)
    //            containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //            currentState = ._EVENING_HABIT_
    //            currentAction = ._INPROGRESS_
    //            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
    //
    //
    //        }else{
    //            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- eveningHabitFinishedAndStartIncompleteNew")
    //            isLastActivityStoppedInRunningState = false
    //
    //            if index == 0{
    //                showAllEveningHabits()
    //            }else{
    //                currentHabitIndex = index-1
    //                if currentHabitIndex >= 0{
    //                    let lastHabit = arrFilteredEveningHabits[currentHabitIndex]
    //                    if let lastHabitId = lastHabit.id{
    //                        if !completedActivities.contains(lastHabitId) && !skippedActivities.contains(lastHabitId){
    //                            currentHabitIndex = -1
    //                        }
    //                    }
    //                }
    //                if currentHabitIndex != -1{
    //                    containerView.addSubview(thirdVcObj!.view)
    //                    containerView.addConstraints(subView: thirdVcObj!.view)
    //                    thirdVcObj!.eveningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
    //                }else{
    //                    showAllEveningHabits()
    //                }
    //            }
    //        }
    //    }
    
    //    func eveningHabitFinishShowShutOff(){//evening habit Sequence Finished
    //        addLog(text: "evening habit Finished")
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
    //        leftMenuVcObj?.habitOver()
    //        shutOffMac()
    //        currentHabitIndex = -1
    //    }
    //
    //    func specialActivityFinish(){//special Activity Sequence Finished
    //        addLog(text: "special Activity Finished")
    //        hideCloseButtons()
    //        removeSubViews()
    //        lblMessage.isHidden = true
    //        mainWindowControllerObj?.window?.close()
    //        hideBlankWindowInSecondaryMonitor()
    //        currentState = ._NOTHING_
    //    }
    //
    //    func activityOver() {//current breaks activity Over
    //        addLog(text:"current activityOver called")
    //        if mainWindowControllerObj?.window?.isVisible == false{
    //            mainWindowControllerObj?.window?.setIsVisible(true)
    //            showBlankWindowInSecondaryMonitor()
    //            setDocBarTo(isHide: false)
    //        }
    //        if isAnyAllowedFocusModeActivityRunning{
    //            closeNudgeFocusAlignmentScoreWindow()
    //        }
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentActivityPlaying = nil
    ////        refreshFocusModeData()
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(thirdVcObj!.view)
    //        containerView.addConstraints(subView: thirdVcObj!.view)
    //        thirdVcObj!.activityFinished(index: currentActivityIndex)
    //        currentState = ._MICRO_BREAK_
    //        currentAction = ._END_
    //    }
    //
    //    func specialActivityOver() {//current special activity Over
    //        addLog(text:"current specialActivity Over called")
    //        if mainWindowControllerObj?.window?.isVisible == false{
    //            mainWindowControllerObj?.window?.setIsVisible(true)
    //            showBlankWindowInSecondaryMonitor()
    //            setDocBarTo(isHide: false)
    //        }
    //        if isAnyAllowedFocusModeActivityRunning{
    //            closeNudgeFocusAlignmentScoreWindow()
    //        }
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentActivityPlaying = nil
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //
    //        refreshFocusModeData()
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(thirdVcObj!.view)
    //        containerView.addConstraints(subView: thirdVcObj!.view)
    //        thirdVcObj!.specialActivityFinished()
    //        currentState = ._SPECIAL_ACTIVITY_
    //        currentAction = ._END_
    //    }
    //
    //    func customRoutineHabitOver() {
    //        addLog(text:"current custom routine Habit Over called")
    //        getHabitsVcObject().stopActivityTimer()
    //        if mainWindowControllerObj?.window?.isVisible == false{
    //            mainWindowControllerObj?.window?.setIsVisible(true)
    //            showBlankWindowInSecondaryMonitor()
    //            setDocBarTo(isHide: false)
    //        }
    //        if isAnyAllowedFocusModeActivityRunning{
    //            closeNudgeFocusAlignmentScoreWindow()
    //        }
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //        if taskPlayerWcObj != nil{
    //            if taskPlayerWcObj?.window?.isVisible ?? false{
    //                taskPlayerVcObj?.getToDosFromPlayer()
    //                taskPlayerWcObj?.window?.close()
    //                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
    //            }
    //        }
    //        refreshFocusModeData()
    //        setAppIconForFocusModeScore(probability: nil)
    //
    //        closePupUpBlockIfVisible()
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //        self.showCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(thirdVcObj!.view)
    //        containerView.addConstraints(subView: thirdVcObj!.view)
    //        thirdVcObj!.customRoutineHabitFinished(index: currentHabitIndex)
    //        currentState = ._CUSTOM_ROUTINE_
    //        currentAction = ._END_
    //    }
    //
    //
    //    func changeCustomRoutineHabit() {//start another Custom habit
    //        addLog(text:"current change Custom Routine Habit called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex += 1
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
    //        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:0)
    //        currentState = ._CUSTOM_ROUTINE_
    //        currentAction = ._INPROGRESS_
    //    }
    //
    //    func changeMorningHabit() {//start another morning habit
    //        addLog(text:"current change Morning Habit called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex += 1
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:0)
    //        currentState = ._MORNING_HABIT_
    //        currentAction = ._INPROGRESS_
    //    }
    //
    //    func changeEveningHabit() {
    //        addLog(text:"current change Evening Habit called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex += 1
    //        if isHighPrioritySequenceGoing{
    //            var newIndexFound = false
    //            while !newIndexFound{
    //                if let cutOffTime = arrFilteredEveningHabits[currentHabitIndex].cutOffTime{
    //                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
    //                    let currentDate = Date()
    //                    if currentDate < cutOffDate{
    //                        if arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
    //                            newIndexFound = true
    //                        }else{
    //                            addLog(text: "evening habit skipped:- this next habit is not High Priority habit:- \(arrFilteredEveningHabits[currentHabitIndex].name)  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
    //                            currentHabitIndex = currentHabitIndex + 1
    //                        }
    //                    }else{
    //                        addLog(text: "evening habit skipped:- cutoff time for this next habit passed:- \(arrFilteredEveningHabits[currentHabitIndex].name)  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
    //                        currentHabitIndex = currentHabitIndex + 1
    //                    }
    //                }else{
    //                    if arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
    //                        newIndexFound = true
    //                    }else{
    //                        addLog(text: "evening habit skipped:- this next habit is not High Priority habit and this habit has no cutOffTime:- \(arrFilteredEveningHabits[currentHabitIndex].name)  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
    //                        currentHabitIndex = currentHabitIndex + 1
    //                    }
    //
    //                }
    //            }
    //        }
    //
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:0)
    //        currentState = ._EVENING_HABIT_
    //        currentAction = ._INPROGRESS_
    //    }
    //
    //    func startSpecialActivity(duration:Int,habit:habit?, activity:breakActivity?){//start special activity
    //        addLog(text: "func:- startSpecialActivity")
    //        if easyPostponeWcObj != nil{
    //            if easyPostponeWcObj?.window?.isVisible ?? false{
    //                easyPostponeWcObj?.window?.close()
    //            }
    //        }
    //
    //        if isFocusModeOnOrPaused(){
    //            addLog(text: "Special Activity start:- Focus Mode Finished")
    //            appdelegate?.tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false)
    //
    //        }
    //        mainWindowControllerObj?.showWindow(self)
    //        showBlankWindowInSecondaryMonitor()
    //
    //        currentState = ._SPECIAL_ACTIVITY_
    //        currentAction = ._INPROGRESS_
    //        self.showCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //
    //        var currentChoice:activityChoice?
    //        if activity != nil{
    //            if activity!.choiceType == ._RANDOM_{
    //                if let randomChoice = activity!.choices.randomElement(){
    //                    currentChoice = randomChoice
    //                }
    //            }
    //        }
    //
    //        timerViewcontrollerObj?.startSpecialActivity(durationSeconds: duration, currentHabit: habit, currentActivity: activity, currentChoice: currentChoice)
    //    }
    //
    //    func startCurrentActivity() {//start break activity
    //        allApiObject.capturePosthog(event: "start-break-activity", metadata: ["routine-type":"break_activity"])
    //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastBreaksStartTime)
    //        addLog(text:"start Current Activity called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //        currentActivityIndex += 1
    //        let activity = arrFinalBreakActivities[currentActivityIndex]
    //        let currentActivity = activity.activity!
    //        if let randomChoice = activity.randomChoice{//currentActivity.choices.randomElement(){
    //            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestions, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
    //        }else{
    //            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestions, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
    //        }
    //
    //        currentState = ._MICRO_BREAK_
    //        currentAction = ._INPROGRESS_
    //    }
    //
    //
    //    func changeActivity() {//start another break activity
    //        addLog(text:"current change Activity called")
    //        self.showCloseButtons()
    //        removeSubViews()
    //        containerView.addSubview(timerViewcontrollerObj!.view)
    //        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
    //
    //        currentActivityIndex += 1
    //
    //        let activity = arrFinalBreakActivities[currentActivityIndex]
    //        let currentActivity = activity.activity!
    //        if let randomChoice = activity.randomChoice{//currentActivity.choices.randomElement(){
    //            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestions, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
    //        }else{
    //            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestions, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
    //        }
    //
    //        currentState = ._MICRO_BREAK_
    //        currentAction = ._INPROGRESS_
    //    }
    //
    //    func habitsFinishedUnlockMachine() {
    //        addLog(text: "morning habit Finished")
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
    //        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
    //        hideCloseButtons()
    //        removeSubViews()
    //        lblMessage.isHidden = false
    //        if let common = configjson.value(forKey: "common") as? NSDictionary{
    //            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
    //        }
    //        currentHabitIndex = -1
    //
    //        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
    //        unfocusedTime = 0
    //        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
    //            if state{
    //                appdelegate?.showMorningPomodoroModeView()
    //            }
    //        }
    //        currentState = ._NOTHING_
    //
    //        if SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled{
    //            showBrainDumpWindow()
    //        }
    //
    //        let currentDate = Date()
    //        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    //        let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
    //
    //        if diffDays > 2{
    //            if UserDefaults.standard.object(forKey: kUserdefaultsEnableScreenTimeShown) == nil &&  UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabledOneTime) == nil{
    //                UserDefaults.standard.set(true, forKey: kUserdefaultsEnableScreenTimeShown)
    //                showTimeTrackerWindow(showingAutomatically:true)
    //                return;
    //            }
    //        }
    //
    //        if diffDays > 3{
    //            if UserDefaults.standard.object(forKey: kUserdefaultsSurveyShown) == nil{
    //                UserDefaults.standard.set(true, forKey: kUserdefaultsSurveyShown)
    //                showSurveyWindow()
    //                return;
    //            }
    //        }
    //
    //
    //        if diffDays > 10{
    //            if UserDefaults.standard.object(forKey: kUserdefaultsGetLateNoMoreShown) == nil{
    //                UserDefaults.standard.set(true, forKey: kUserdefaultsGetLateNoMoreShown)
    //                showLateNoMoreWindow()
    //            }
    //        }
    //        leftMenuVcObj?.habitOver()
    //    }
    
    //    @objc func unlockMachine() {
    //        addLog(text:"current unlockMachine called")
    //
    //        lblMessage.isHidden = true
    //        mainWindowControllerObj?.window?.close()
    //        hideBlankWindowInSecondaryMonitor()
    //        activityPostponeCount = 0
    //        activitySkipCount = 0
    //        if isFirstRun{//welcome routine k baad set krenge (when first time)
    //            UserDefaults.standard.removeObject(forKey: kUserdefaultsPasswordSetInOnboarding)
    //            SettingsManagerObject.isFullScreenEnabled = false
    //            SettingsManagerObject.isCuddlyModeEnabled = true
    //            SettingsManagerObject.isEasySkipEnabled = true
    //            SettingsManagerObject.doNotBlockUrlsDuringSuperPomodoroBreaksDefaultValue = true
    //            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
    //            SettingsManagerObject.immediatelyBlockDistractingSites = false
    //            SettingsManagerObject.immediatelyBlockDistractingApps = false
    //
    //            SettingsManagerObject.isGeekModeEnabled = false // for new user app is in simple mode
    //
    //            if UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool == false{
    //                UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
    //                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
    //            }
    //            appdelegate!.needToCheckEmailVerification = false// if onboarding then dont show till menu tour is over
    //            appdelegate!.getUserSubscriptionInfo()
    //            appdelegate!.statusbutton?.action = nil
    //            showMenuTourWindow()
    //            UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
    //        }else{
    //            setActivityTimer()
    //        }
    //
    //        DispatchQueue.global().async {
    //            DispatchQueue.main.async {
    //                stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
    //            }
    //        }
    //    }
    
    //    func stopActivityTimer(){
    //        if breakTimer != nil{
    //            breakTimer?.invalidate()
    //            breakTimer = nil
    //            if isWaitingForInactivityToStartMicroBreak{
    //                self.breakInactivitySecondsToCheck = 5
    //                self.isWaitingForInactivityToStartMicroBreak = false
    //                self.inActivityStartTime = nil
    //                setFocusBearIconToNormal()
    //            }
    //
    //            addLog(text: "stopActivityTimer")
    //        }
    //    }
    
    //    func setActivityTimer(){
    //        addLog(text: "Break Activity Timer reset Done.")
    //        if arrAllbreakActivities.count != 0 {
    //            DispatchQueue.global().sync {
    //                print("breakAfterMinutesxxxx")
    //                stopActivityTimer()
    //                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(breakAfterMinutes*60), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)
    //
    //                RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
    //            }
    //        }
    //    }
    //    var isBreakActivityPostponeInsideAllowedHabit = false// using this beacuse we dont want reset activity timer again (in resuming habit) if user has postponed activity inside allow app habit
    //    func postponeBreakActivitiesFor(minutes:Int, secondsToPostpone:Int?, isFromBreakWarningWindow:Bool){
    //        var seconds = 0
    //        if secondsToPostpone != nil{
    //            seconds = secondsToPostpone!
    //            if seconds == 0 && minutes != 0{
    //                seconds = minutes*60
    //            }
    //        }else{
    //            seconds = minutes*60
    //        }
    //
    //        addLog(text: "postpone Break Activities, Timer reset Done:- \(seconds) seconds")
    //        hideCloseButtons()
    //        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
    //        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
    //
    //        // isFromBreakWarningWindow added on 24/7/25 v 1.26.394
    //        if currentAction != ._START_ && currentAction != ._BRAIN_DUMP_ && !isFromBreakWarningWindow{
    //            if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
    //                let currentDate = Date()
    //                let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
    //                if diffSeconds > 0{
    //                    var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
    //                    arrDuration.append(diffSeconds)
    //                    UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
    //                }
    //                UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
    //            }
    //        }
    //
    //        removeSubViews()
    //        currentState = ._NOTHING_
    //        mainWindowControllerObj?.window?.close()
    //        hideBlankWindowInSecondaryMonitor()
    //        if arrAllbreakActivities.count != 0 {
    //            DispatchQueue.global().sync {//async {
    //                print("breakAfterMinutesxxxx")
    //                stopActivityTimer()
    //                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)//  seconds kro
    //            RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
    //            }
    //        }
    //        if popUpCheckListWcObj != nil{
    //            if popUpCheckListWcObj?.window?.isVisible ?? false{
    //                popUpCheckListWcObj?.window?.close()
    //            }
    //        }
    //        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
    //            isBreakActivityPostponeInsideAllowedHabit = true
    //            DispatchQueue.global().async {
    //                sleep(5)
    //                self.isBreakActivityPostponeInsideAllowedHabit = false
    //            }
    //            isBreakActivityExecuteFromMorningHabit = false
    //            isBreakActivityExecuteFromEveningHabit = false
    //            appdelegate!.backgroundThread()
    //        }
    //        if isBreakActivityExecuteFromPostponeMorningHabit{
    //            currentState = ._POSTPON_MORNING_HABIT_
    //            isBreakActivityExecuteFromPostponeMorningHabit = false
    //        }
    //
    //        if isBreakActivityExecuteFromPostponeEveningHabit{
    //            currentState = ._POSTPON_EVENING_HABIT_
    //            isBreakActivityExecuteFromPostponeEveningHabit = false
    //        }
    //        writeStringToHabitInfo(isFinishTime: true, activityName: "")
    //    }
    //
    //
    //    func breaksScreenIsIdleResetBreaks(){
    //        addLog(text: "breaksScreenIsIdleResetBreaks")
    //        allApiObject.capturePosthog(event: "break-cancelled-due-to-user-inactivity", metadata: [:])
    //        hideCloseButtons()
    //        removeSubViews()
    //        activityPostponeCount = 0
    //        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
    //        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
    //        print(infoDic)
    //        currentActivityIndex = -1
    //        unlockMachine()
    //        currentState = ._NOTHING_
    //
    //        if shouldShowPomodoroAfterBreak{
    //            shouldShowPomodoroAfterBreak = false
    //            if SettingsManagerObject.isGeekModeEnabled{
    //                if let date = shouldEndPomodoroBreakAtTime{
    //                    let currentDate = Date()
    //                    if currentDate > date{
    //                        appdelegate!.showAutoPomodoroModeView()
    //                    }else{
    //                        let diffSeconds = Calendar.current.dateComponents([.second], from: currentDate, to: date).second ?? 0
    //                        appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(diffSeconds))
    //                        showSmallTimerWindow(durationSeconds: diffSeconds, msg: "", isFocusBreak: true, currentTimerValue:0)
    //                        if isAppEnable{
    //                            isFocusBreakOn = true
    //                        }
    //                    }
    //                }else{
    //                    appdelegate!.showAutoPomodoroModeView()
    //                }
    //            }
    //        }
    //        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
    //            isBreakActivityExecuteFromMorningHabit = false
    //            isBreakActivityExecuteFromEveningHabit = false
    //            addLog(text: "breaksScreenIsIdleResetBreaks:- Try resume Habit Routine")
    //            appdelegate!.backgroundThread()
    //        }
    //        if isBreakActivityExecuteFromPostponeMorningHabit{
    //            currentState = ._POSTPON_MORNING_HABIT_
    //            isBreakActivityExecuteFromPostponeMorningHabit = false
    //            addLog(text: "breaksScreenIsIdleResetBreaks:- activity was started from postpone morning habit. Try postpone Habit Routine")
    //        }
    //        if isBreakActivityExecuteFromPostponeEveningHabit{
    //            currentState = ._POSTPON_EVENING_HABIT_
    //            isBreakActivityExecuteFromPostponeEveningHabit = false
    //            addLog(text: "breaksScreenIsIdleResetBreaks:- activity was started from postpone evening habit. Try postpone Habit Routine")
    //        }
    //        writeStringToHabitInfo(isFinishTime: true, activityName: "")
    //    }
    //
    //    func savePostpneCount(state:CURRENTSTATE){
    //        if state == ._MORNING_HABIT_{
    //            if arrFilteredMorningHabits.count != 0 {
    //                let infoDic:[String:Any] = ["sequenceId":arrFilteredMorningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":Date()]
    //                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
    //                print(infoDic)
    //            }
    //        }else if state == ._EVENING_HABIT_{
    //            if arrFilteredEveningHabits.count != 0 {
    //
    //                var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    //
    //                let curreentDate = Date()
    //                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
    //                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    //                    startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate
    //
    //                }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
    //
    //                }
    //
    //                let infoDic:[String:Any] = ["sequenceId":arrFilteredEveningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":startDate]
    //                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
    //                print(infoDic)
    //            }
    //        }
    //    }
    //    func refreshLastPostponeCount(){
    //        var lastSavedPostponeTime = Date()
    //        activityPostponeCount = 0
    //        var lastSavedPostponeCount = activityPostponeCount
    //        var lastSavedSequenceId = ""
    //        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //
    //        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequencePostponeInfo) as? [String:Any]{
    //
    //            if let id =  infoDic["sequenceId"] as? String{
    //                lastSavedSequenceId = id
    //            }
    //            if let postponeCount =  infoDic["postponeCount"] as? Int{
    //                lastSavedPostponeCount = postponeCount
    //            }
    //            if let date =  infoDic["date"] as? Date{
    //                lastSavedPostponeTime = date
    //            }
    //        }
    //        if currentState == ._MORNING_HABIT_{
    //            if arrFilteredMorningHabits.count != 0 {
    //                if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
    //                    activityPostponeCount = lastSavedPostponeCount
    //                }
    //            }
    //        }else if currentState == ._EVENING_HABIT_{
    //            if arrFilteredEveningHabits.count != 0 {
    //                if lastSavedSequenceId == arrFilteredEveningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
    //                    activityPostponeCount = lastSavedPostponeCount
    //                }
    //            }
    //        }
    //    }
    //    func postponeMorningHabitFor(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, showAskIntention:Bool){
    //        var showAskIntention = showAskIntention
    //
    //        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
    //            addLog(text: "postponeMorningHabitFor:- strictness level is super gentle so don't show postpone Intention view")
    //            showAskIntention = false
    //        }
    //        if showAskIntention{
    //            self.presentAsSheet(getAskPostponeIntentionVcObject())
    //            askPostponeIntentionVcObj?.resetData(minutes: minutes, secondsToPostpone: secondsToPostpone, showAskFocusModeView: showAskFocusModeView, lastCurrentState: ._MORNING_HABIT_)
    //        }else{
    //            var seconds = 0
    //            if secondsToPostpone != nil{
    //                seconds = secondsToPostpone!
    //                if seconds == 0 && minutes != 0{
    //                    seconds = minutes*60
    //                }
    //            }else{
    //                seconds = minutes*60
    //            }
    //            addLog(text: "postpone morning habits, Timer reset Done:- \(seconds) seconds")
    //            savePostpneCount(state: ._MORNING_HABIT_)
    //
    //            if currentState != ._CUSTOM_ROUTINE_{
    //                if currentAction == ._INPROGRESS_{
    //                    isLastActivityStoppedInRunningState = true
    //                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
    //                }else{
    //                    isLastActivityStoppedInRunningState = false
    //                    lastActivityRunningId = ""
    //                }
    ////                hideCloseButtons() //
    ////                removeSubViews() //
    //
    //                //Extend postpone time not working for 2 minute warning popup#923
    //                if smallCountDownWcObj != nil && currentState == ._POSTPON_MORNING_HABIT_{
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //
    //                if !isFocusModeOn(){
    //                    closeTaskPlayerWindowIfVisible()
    //                }
    //                currentState = ._POSTPON_MORNING_HABIT_
    ////                mainWindowControllerObj?.window?.close() //
    ////                hideBlankWindowInSecondaryMonitor() //
    //            }
    //
    //            if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                if smallCountDownWcObj?.window != nil{
    //                    if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                        if currentHabitPlaying != nil{
    //                            getSmallCountDownWindowObject().window!.close()
    //                        }
    //                    }
    //                }
    //            }
    //            if popUpCheckListWcObj != nil{
    //                if popUpCheckListWcObj?.window?.isVisible ?? false{
    //                    popUpCheckListWcObj?.window?.close()
    //                }
    //            }
    //
    //
    //            if currentState != ._CUSTOM_ROUTINE_{
    //                if isAnyAllowedFocusModeActivityRunning{
    //                    closeNudgeFocusAlignmentScoreWindow()
    //                }
    //                isAnyAllowedFocusModeActivityRunning = false
    //                currentHabitPlaying = nil
    //
    //                if toolBoxWcObj != nil{
    //                    if toolBoxWcObj!.window!.isVisible{
    //                        toolBoxWcObj?.window?.close()
    //                    }
    //                }
    //                if !isFocusModeOn(){
    //                    refreshFocusModeData()
    //                    setAppIconForFocusModeScore(probability: nil)
    //                }
    //                closePupUpBlockIfVisible()
    //
    //                appdelegate?.timerAllowUrlForActivity?.invalidate()
    //                appdelegate?.timerAllowAppForActivity?.invalidate()
    //            }
    //
    //            if arrFilteredMorningHabits.count != 0 {
    //                DispatchQueue.global().sync{//async {
    //                    if self.postponeTimer != nil{
    //                        self.postponeTimer?.invalidate()
    //                        self.postponeTimer = nil
    //                    }
    //                    self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.resumeMorningHabit), userInfo: nil, repeats: false)//  seconds
    //                    RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
    //
    //                    if seconds > 120{
    //                        setPostponeNotificationTimer(duration: ((seconds) - 120))
    //                    }
    //                }
    //            }
    //
    //            // check for breaktimer nil becasuse whenever user extended focus session for another 15 minutes it also extent postpone duration and then breaks always reset so if break timer is nil then only set it. this willl solve (reset breaktimer awalys and break didn't come ) problem #1272
    //            if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                if breakTimer == nil{
    //                    setActivityTimer()
    //                }
    //            }
    //            if currentState != ._CUSTOM_ROUTINE_{
    //                if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled{
    //                    appdelegate?.menuShowPomodoroModeView()
    //                    if pomodoroWindowControllerObj != nil{
    //                        if pomodoroWindowControllerObj?.window?.isVisible ?? false{
    //                            pomodoroVcObj!.textFieldWorkDuration.integerValue = minutes - 1
    //                            pomodoroVcObj!.updateBreakDuration()
    //                        }
    //                    }
    //                }
    //            }
    //            writeStringToHabitInfo(isFinishTime: true, activityName: "")
    //
    //            menuViewControllerObj?.reloadIfNeeded()
    //            leftMenuVcObj?.habitOver()
    //        }
    //    }
    //
    //    func postponeCustomRoutineFor(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, showAskIntention:Bool){
    //
    //        var seconds = 0
    //        if secondsToPostpone != nil{
    //            seconds = secondsToPostpone!
    //            if seconds == 0 && minutes != 0{
    //                seconds = minutes*60
    //            }
    //        }else{
    //            seconds = minutes*60
    //        }
    //        addLog(text: "postpone Custom habits ")
    //
    //
    //        hideCloseButtons()
    //        removeSubViews()
    //
    //        if !isFocusModeOn(){
    //            closeTaskPlayerWindowIfVisible()
    //        }
    //        mainWindowControllerObj?.window?.close()
    //        hideBlankWindowInSecondaryMonitor()
    //        currentState = ._NOTHING_
    //
    //        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //            if smallCountDownWcObj?.window != nil{
    //                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                    if currentHabitPlaying != nil{
    //                        getSmallCountDownWindowObject().window!.close()
    //                    }
    //                }
    //            }
    //        }
    //        if popUpCheckListWcObj != nil{
    //            if popUpCheckListWcObj?.window?.isVisible ?? false{
    //                popUpCheckListWcObj?.window?.close()
    //            }
    //        }
    //
    //        if isAnyAllowedFocusModeActivityRunning{
    //            closeNudgeFocusAlignmentScoreWindow()
    //        }
    //        isAnyAllowedFocusModeActivityRunning = false
    //        currentHabitPlaying = nil
    //
    //        if toolBoxWcObj != nil{
    //            if toolBoxWcObj!.window!.isVisible{
    //                toolBoxWcObj?.window?.close()
    //            }
    //        }
    //        if !isFocusModeOn(){
    //            refreshFocusModeData()
    //            setAppIconForFocusModeScore(probability: nil)
    //        }
    //        closePupUpBlockIfVisible()
    //
    //        appdelegate?.timerAllowUrlForActivity?.invalidate()
    //        appdelegate?.timerAllowAppForActivity?.invalidate()
    //
    //        if !arrAllCustomRoutine[currentRoutineIndex].triggerOnDemand{
    //            let currentDate = Date()
    //            let secondsToAdd: TimeInterval = TimeInterval(seconds)
    //            let nextSheduledTime = Calendar.current.date(byAdding: .second, value: Int(secondsToAdd), to: currentDate)
    //            arrAllCustomRoutine[currentRoutineIndex].nextSheduledTime = nextSheduledTime
    //        }
    //
    //        menuViewControllerObj?.reloadIfNeeded()
    //        isCustomRoutineWasRunningBetweenMorningHabit = false
    //        isCustomRoutineWasRunningBetweenEveningHabit = false
    //    }
    //
    //
    //    func postponeEveningHabitFor(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, showAskIntention:Bool){
    //        var showAskIntention = showAskIntention
    //
    //        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
    //            addLog(text: "postponeMorningHabitFor:- strictness level is super gentle so don't show postpone Intention view")
    //            showAskIntention = false
    //        }
    //
    //        if showAskIntention{
    //            self.presentAsSheet(getAskPostponeIntentionVcObject())
    //            askPostponeIntentionVcObj?.resetData(minutes: minutes, secondsToPostpone: secondsToPostpone, showAskFocusModeView: showAskFocusModeView, lastCurrentState: ._EVENING_HABIT_)
    //        }else{
    //            var seconds = 0
    //            if secondsToPostpone != nil{
    //                seconds = secondsToPostpone!
    //                if seconds == 0 && minutes != 0{
    //                    seconds = minutes*60
    //                }
    //            }else{
    //                seconds = minutes*60
    //            }
    //            addLog(text: "postpone evening habits, Timer reset Done:- \(seconds) seconds")
    //
    //            savePostpneCount(state: ._EVENING_HABIT_)
    //            eveningRoutineLastPostponeTime = Date()
    //            if currentAction == ._INPROGRESS_{
    //                isLastActivityStoppedInRunningState = true
    //                lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
    //            }else{
    //                isLastActivityStoppedInRunningState = false
    //                lastActivityRunningId = ""
    //            }
    //
    //            hideCloseButtons()
    //            removeSubViews()
    //            //Extend postpone time not working for 2 minute warning popup#923
    //            if smallCountDownWcObj != nil && currentState == ._POSTPON_EVENING_HABIT_{
    //                if smallCountDownWcObj?.window != nil{
    //                    if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
    //                        getSmallCountDownWindowObject().window?.close()
    //                    }
    //                }
    //            }
    //            //
    //            if !isFocusModeOn(){
    //                closeTaskPlayerWindowIfVisible()
    //            }
    //            currentState = ._POSTPON_EVENING_HABIT_
    ////            mainWindowControllerObj?.window?.close() //
    ////            hideBlankWindowInSecondaryMonitor() // 
    //            if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                if smallCountDownWcObj?.window != nil{
    //                    if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                        if currentHabitPlaying != nil{
    //                            getSmallCountDownWindowObject().window!.close()
    //                        }
    //                    }
    //                }
    //            }
    //
    //            if popUpCheckListWcObj != nil{
    //                if popUpCheckListWcObj?.window?.isVisible ?? false{
    //                    popUpCheckListWcObj?.window?.close()
    //                }
    //            }
    //            if isAnyAllowedFocusModeActivityRunning{
    //                closeNudgeFocusAlignmentScoreWindow()
    //            }
    //            isAnyAllowedFocusModeActivityRunning = false
    //            currentHabitPlaying = nil
    //
    //            if toolBoxWcObj != nil{
    //                if toolBoxWcObj!.window!.isVisible{
    //                    toolBoxWcObj?.window?.close()
    //                }
    //            }
    //
    //            if !isFocusModeOn(){
    //                refreshFocusModeData()
    //                setAppIconForFocusModeScore(probability: nil)
    //            }
    //            closePupUpBlockIfVisible()
    //
    //            appdelegate?.timerAllowUrlForActivity?.invalidate()
    //            appdelegate?.timerAllowAppForActivity?.invalidate()
    //
    //            if arrFilteredEveningHabits.count != 0 {
    //                DispatchQueue.global().sync{//async {
    //                    if self.postponeTimer != nil{
    //                        self.postponeTimer?.invalidate()
    //                        self.postponeTimer = nil
    //                    }
    //                    self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.resumeEveningHabit), userInfo: nil, repeats: false)//  seconds
    //                    RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
    //
    //                    if seconds > 120{
    //                        setPostponeNotificationTimer(duration: ((seconds) - 120))
    //                    }
    //                }
    //            }
    //
    //            if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                if breakTimer == nil{
    //                    setActivityTimer()
    //                }
    //            }
    //            if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled{
    //                appdelegate?.menuShowPomodoroModeView()
    //                if pomodoroWindowControllerObj != nil{
    //                    if pomodoroWindowControllerObj?.window?.isVisible ?? false{
    //                        pomodoroVcObj!.textFieldWorkDuration.integerValue = minutes - 1
    //                        pomodoroVcObj!.updateBreakDuration()
    //                    }
    //                }
    //            }
    //            writeStringToHabitInfo(isFinishTime: true, activityName: "")
    //
    //            menuViewControllerObj?.reloadIfNeeded()
    //        }
    //    }
    //
    //    func postponeFocusSummaryFor(minutes:Int, showAskIntention:Bool){
    //        addLog(text: "postpone Focus Summary Done:- \(minutes) minutes")
    //
    //        var showAskIntention = showAskIntention
    //
    //        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
    //            addLog(text: "postponeFocusSummaryFor:- strictness level is super gentle so don't show postpone Intention view")
    //            showAskIntention = false
    //        }
    //        if showAskIntention{
    //            self.presentAsSheet(getAskPostponeIntentionVcObject())
    //            askPostponeIntentionVcObj?.resetData(minutes: minutes, secondsToPostpone: nil, showAskFocusModeView: false, lastCurrentState: ._FOCUS_SUMMARY_)
    //        }else{
    //            hideCloseButtons()
    //            removeSubViews()
    //            currentState = ._POSTPON_FOCUS_SUMMARY_
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //            DispatchQueue.global().sync{//async {
    //                if self.postponeTimer != nil{
    //                    self.postponeTimer?.invalidate()
    //                    self.postponeTimer = nil
    //                }
    //                focusSummaryLastPostponeTime = Date()
    //                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.resumeFocusSummary), userInfo: nil, repeats: false)//  minutes*60 kroTimeInterval(minutes*60)
    //                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
    //
    //                if minutes > 2{
    //                    setPostponeNotificationTimer(duration: ((minutes*60) - 120))
    //                }
    //            }
    //            if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                if breakTimer == nil{
    //                    setActivityTimer()
    //                }
    //            }
    //            menuViewControllerObj?.reloadIfNeeded()
    //            if SettingsManagerObject.isGeekModeEnabled{
    //                appdelegate?.menuShowPomodoroModeView()
    //                if pomodoroWindowControllerObj != nil{
    //                    if pomodoroWindowControllerObj?.window?.isVisible ?? false{
    //                        pomodoroVcObj!.textFieldWorkDuration.integerValue = minutes - 1
    //                        pomodoroVcObj!.updateBreakDuration()
    //                    }
    //                }
    //            }
    //        }
    //    }
    //
    //    func setPostponeNotificationTimer(duration:Int){
    //
    //        if self.postponeNotificationTimer != nil{
    //            self.postponeNotificationTimer?.invalidate()
    //            self.postponeNotificationTimer = nil
    //        }
    //        self.postponeNotificationTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.showPostponeEndNotification), userInfo: nil, repeats: false)
    //        RunLoop.main.add((postponeNotificationTimer!), forMode: RunLoop.Mode.common)
    //    }
    //
    //    @objc func showPostponeEndNotification(){
    //        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_MORNING_HABIT_ || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit && !isCustomRoutineWasRunningBetweenMorningHabit) || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit && !isCustomRoutineWasRunningBetweenEveningHabit){
    //            var msg = "Habit resumes in"
    //            if let common = configjson.value(forKey: "common") as? NSDictionary{
    //                msg = common.value(forKey: "postponeEndsText") as? String ?? msg
    //            }
    //            addLog(text: "Show Postpone End Notification")
    //            showSmallTimerWindow(durationSeconds: 120, msg: msg, isFocusBreak: true, currentTimerValue: 0)
    //        }
    //    }
    //    @objc func resumeMorningHabit(){// func name "backgrounThread" will do work for showing morning routing again we just need to false this (currentState) variable
    //        addLog(text: "Morning habits postpone finished")
    //        if currentState == ._POSTPON_MORNING_HABIT_{
    //            currentState = ._NOTHING_
    //            stopActivityTimer()
    //            if appdelegate!.isActivityTimerPaused{// if habit is postponed and system goes to sleep then  it stops break activity timer and while system is in sleep mode at that time postpone  time finish so it need to change isActivityTimerPaused to false otherwise when system wakes up it will again set activity timer
    //                appdelegate!.isActivityTimerPaused = false
    //            }
    //        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
    //            stopActivityCountDownTimer()
    //            if currentActivityPlaying != nil{
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //            }
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //
    //            isBreakActivityExecuteFromPostponeMorningHabit = false
    //            currentState = ._NOTHING_
    //            closePupUpBlockIfVisible()
    //            currentActivityPlaying = nil
    //        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit && !isCustomRoutineWasRunningBetweenMorningHabit{
    //            stopActivityCountDownTimer()
    //            if currentActivityPlaying != nil{
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //            }
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //            closePupUpBlockIfVisible()
    //            currentHabitPlaying = nil
    //            isCustomRoutineWasRunningInPostponeMorningHabit = false
    //            currentState = ._NOTHING_
    //        }
    //        hideCustomRoutineTimeWindowIfVisible()// hide custom routine coming window if visible
    //    }
    //
    //    @objc func resumeEveningHabit(){// func name "backgrounThread" will do work for showing evening routing again we just need to false this (currentState) variable
    //        addLog(text: "Evening habits postpone finished")
    //        if currentState == ._POSTPON_EVENING_HABIT_{
    //            currentState = ._NOTHING_
    //            stopActivityTimer()
    //            if appdelegate!.isActivityTimerPaused{// if habit is postponed and system goes to sleep then  it stops break activity timer and while system is in sleep mode at that time postpone  time finish so it need to change isActivityTimerPaused to false otherwise when system wakes up it will again set activity timer
    //                appdelegate!.isActivityTimerPaused = false
    //            }
    //        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
    //            stopActivityCountDownTimer()
    //            if currentActivityPlaying != nil{
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //            }
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //
    //            isBreakActivityExecuteFromPostponeEveningHabit = false
    //            currentState = ._NOTHING_
    //            closePupUpBlockIfVisible()
    //            currentActivityPlaying = nil
    //        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit && !isCustomRoutineWasRunningBetweenEveningHabit{
    //            stopActivityCountDownTimer()
    //            if currentActivityPlaying != nil{
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //            }
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //            closePupUpBlockIfVisible()
    //            currentHabitPlaying = nil
    //            isCustomRoutineWasRunningInPostponeEveningHabit = false
    //            currentState = ._NOTHING_
    //        }
    //    }
    //
    //    @objc func resumeFocusSummary(){// func name "backgrounThread" will do work for showing morning routing again we just need to false this (isMorningRoutinePostpone) variable
    //        addLog(text: "Focus Summary postpone finished")
    //        if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
    //            stopActivityCountDownTimer()
    //            if currentActivityPlaying != nil{
    //                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
    //                    if smallCountDownWcObj?.window != nil{
    //                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                            getSmallCountDownWindowObject().window?.close()
    //                        }
    //                    }
    //                }
    //            }
    //            mainWindowControllerObj?.window?.close()
    //            hideBlankWindowInSecondaryMonitor()
    //            closePupUpBlockIfVisible()
    //            currentHabitPlaying = nil
    //            isCustomRoutineWasRunningInPostponeEveningHabit = false
    //            currentState = ._NOTHING_
    //        }
    //        currentState = ._NOTHING_
    //    }
    //
    //    func activityFinishedUnlockMachine() {
    //        addLog(text: "Break Activities Finished")
    //        hideCloseButtons()
    //        removeSubViews()
    //        activityPostponeCount = 0
    //        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
    //        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
    //        print(infoDic)
    //
    //        if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
    //            let currentDate = Date()
    //            let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
    //            if diffSeconds > 0{
    //                var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
    //                arrDuration.append(diffSeconds)
    //                UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
    //            }
    //            UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
    //        }
    //
    //        currentActivityIndex = -1
    //        unlockMachine()
    //        currentState = ._NOTHING_
    //        if shouldShowPomodoroAfterBreak{
    //            shouldShowPomodoroAfterBreak = false
    //            if SettingsManagerObject.isGeekModeEnabled{
    //                if let date = shouldEndPomodoroBreakAtTime{
    //                    let currentDate = Date()
    //                    if currentDate > date{
    //                        appdelegate!.showAutoPomodoroModeView()
    //                    }else{
    //                        let diffSeconds = Calendar.current.dateComponents([.second], from: currentDate, to: date).second ?? 0
    //                        appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(diffSeconds))
    //                        showSmallTimerWindow(durationSeconds: diffSeconds, msg: "", isFocusBreak: true, currentTimerValue:0)
    //                        if isAppEnable{
    //                            isFocusBreakOn = true
    //                        }
    //                    }
    //                }else{
    //                    appdelegate!.showAutoPomodoroModeView()
    //                }
    //            }
    //        }
    //        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
    //            if !notes.isEmpty{
    //                showBrainDumpWindow()
    //            }
    //        }
    //        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
    //            isBreakActivityExecuteFromMorningHabit = false
    //            isBreakActivityExecuteFromEveningHabit = false
    //            addLog(text: "Break Activity Finished:- Try resume Habit Routine")
    //            appdelegate!.backgroundThread()
    //        }
    //        if isBreakActivityExecuteFromPostponeMorningHabit{
    //            currentState = ._POSTPON_MORNING_HABIT_
    //            isBreakActivityExecuteFromPostponeMorningHabit = false
    //            addLog(text: "Break Activity Finished:- activity was started from postpone morning habit. Try postpone Habit Routine")
    //        }
    //        if isBreakActivityExecuteFromPostponeEveningHabit{
    //            currentState = ._POSTPON_EVENING_HABIT_
    //            isBreakActivityExecuteFromPostponeEveningHabit = false
    //            addLog(text: "Break Activity Finished:- activity was started from postpone evening habit. Try postpone Habit Routine")
    //        }
    //
    //        var microBreaksDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsMicroBreaksDoneCount) as? Int ?? 0//
    //        microBreaksDoneCount += 1
    //        UserDefaults.standard.set(microBreaksDoneCount, forKey: kUserdefaultsMicroBreaksDoneCount)
    //    }
    //
    //    func customRoutineFinishedUnlockMachine() {
    //        addLog(text: "custom Routine Finished")
    //        hideCloseButtons()
    //        removeSubViews()
    //        currentHabitIndex = -1
    //
    //        unlockMachine()
    //        currentState = ._NOTHING_
    //        isCustomRoutineWasRunningBetweenMorningHabit = false
    //        isCustomRoutineWasRunningBetweenEveningHabit = false
    //    }
    //
    //    func breathingFinishedUnlockMachine(){
    //        addLog(text: "breathing Finished")
    //        hideCloseButtons()
    //        removeSubViews()
    //        lblMessage.isHidden = true
    //        unlockMachine()
    //        currentState = ._NOTHING_
    //    }
    
    //🥱😣😫
    // prevent user sleep on ka alog sahi krdena
    //    var breakInactivitySecondsToCheck = 5
    //    var isWaitingForInactivityToStartMicroBreak = false
    //    var inActivityStartTime:Date?
    //    @objc func timeToStartBreakActivities() {
    //        DispatchQueue.main.async {
    //            addLog(text: "Initiating Break Activities")
    //            self.breakTimer?.invalidate()
    //            self.breakTimer = nil
    //
    //
    //            if !SettingsManagerObject.isMicroBreaksEnabled{
    //                self.setActivityTimer()
    //                addLog(text: "Breaks are not enabled :- Break Activities cancelled.")
    //                if self.isWaitingForInactivityToStartMicroBreak{
    //                    self.breakInactivitySecondsToCheck = 5
    //                    self.isWaitingForInactivityToStartMicroBreak = false
    //                    self.inActivityStartTime = nil
    //                    setFocusBearIconToNormal()
    //                }
    //                return;
    //            }
    //
    //            if let disableBreaksForTodayDate = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date{
    //                if Calendar.current.isDateInToday(disableBreaksForTodayDate){
    //                    self.setActivityTimer()
    //                    addLog(text: "Breaks are disabled for today :- Break Activities cancelled.")
    //
    //                    if self.isWaitingForInactivityToStartMicroBreak{
    //                        self.breakInactivitySecondsToCheck = 5
    //                        self.isWaitingForInactivityToStartMicroBreak = false
    //                        self.inActivityStartTime = nil
    //                        setFocusBearIconToNormal()
    //                    }
    //
    //                    return;
    //                }else{
    //                    UserDefaults.standard.removeObject(forKey: kUserdefaultsDisableBreaksForToday)
    //                }
    //            }
    //
    //            if currentState == ._SHUTOFFMAC_{
    //                addLog(text: "App is in shutoff state, Break Activities cancelled.")
    //                return;
    //            }
    //            if currentState == ._ABORT_{
    //                addLog(text: "App state is abort, Break Activities cancelled.")
    //                return;
    //            }
    //
    ////            if isShutOffTimeGoing(){
    ////                if currentState != ._EVENING_HABIT_ && currentState != ._POSTPON_EVENING_HABIT_{
    ////                    addLog(text: "not working hours, Break Activities cancelled.")
    ////                    return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary  k time per bhi rreturn ho jayga
    ////                }
    ////            }
    //
    //            if isShutOffTimeGoing(){
    //                if currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_EVENING_HABIT_{
    //                    if !SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                        addLog(text: "Routine is postponed. Show breaks in Postpone not enabled, Break Activities cancelled.")
    //                        return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary  k time per bhi rreturn ho jayga
    //                    }
    //                }else if currentState != ._EVENING_HABIT_ {
    //                    addLog(text: "not working hours, Break Activities cancelled.")
    //                    return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary  k time per bhi rreturn ho jayga
    //                }
    //            }
    //
    //
    //            //
    //            if currentState == ._CUSTOM_ROUTINE_{
    //                self.setActivityTimer()
    //                addLog(text: "Custom routine is running :- Break Activities cancelled.")
    //                return;
    //            }
    //
    //            if arrAllbreakActivities.count == 0 {
    //                self.setActivityTimer()
    //                addLog(text: "Break Activities count is 0 :- Break Activities cancelled.")
    //                return;
    //            }
    //            if currentState == ._SPECIAL_ACTIVITY_{
    //                self.setActivityTimer()
    //                addLog(text: "Special activity is running :- Break Activities cancelled.")
    //                return;
    //            }
    //
    //            if popupAppointmentTimeWcObj != nil{
    //                if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
    //                    addLog(text: "Appointment popup is visible :- Break Activities cancelled.")
    //                    return;
    //                }
    //            }
    //
    //            let isFocusModeOnOrPaused = isFocusModeOnOrPaused()
    //            if isFocusModeOnOrPaused && isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
    //                self.setActivityTimer()
    //                addLog(text: "Pomodoro mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
    //                return;
    //            }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
    //                self.setActivityTimer()
    //                addLog(text: "Super Pomodoro mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
    //                return;
    //            }else if isFocusModeOnOrPaused && isSkipBreakActivityDuringFocus{
    //                self.setActivityTimer()
    //                addLog(text: "Focus mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
    //                return;
    //            }
    //
    //
    //            //show the break as soon as there are 5 seconds of inactivity
    //            var lastEvent:CFTimeInterval = 0
    //            lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
    //
    //            let idleTimeValue = Int(lastEvent)
    //            if idleTimeValue < self.breakInactivitySecondsToCheck{
    //                if !self.isWaitingForInactivityToStartMicroBreak{
    //                    self.isWaitingForInactivityToStartMicroBreak = true
    //                    self.inActivityStartTime = Date()
    //                }
    //                if let startTime = self.inActivityStartTime{
    //                    let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: Date()).second ?? 0
    //                    if diffSeconds < 120{// 2 minutes
    //                        self.breakInactivitySecondsToCheck = 5
    //                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactiveWaiting_icon"))
    //                    }else if diffSeconds > 600{// 10 minutes
    //                        self.breakInactivitySecondsToCheck = 1
    //                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactive5Minutes_icon"))
    //                    }else if diffSeconds > 300{// 5 minutes
    //                        self.breakInactivitySecondsToCheck = 2
    //                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactive5Minutes_icon"))
    //                    }else if diffSeconds > 120{// 2 minutes
    //                        self.breakInactivitySecondsToCheck = 3
    //                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactive2Minutes_icon"))
    //                    }
    //                    addLog(text: "waiting since \(diffSeconds) seconds")
    //                }
    //
    //                addLog(text: "idleTimeValue is less then \(self.breakInactivitySecondsToCheck) seconds :- try break activities after \(self.breakInactivitySecondsToCheck) seconds.")
    //                print("idleTimeValue is less then \(self.breakInactivitySecondsToCheck) seconds :- try break activities after \(self.breakInactivitySecondsToCheck) seconds.")
    //                DispatchQueue.global().sync {
    //                    print("breakAfterMinutesxxxx")
    //                    self.breakTimer?.invalidate()
    //                    self.breakTimer = nil
    //                    self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.breakInactivitySecondsToCheck), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)
    //
    //                    RunLoop.main.add((self.breakTimer!), forMode: RunLoop.Mode.common)
    //                }
    //
    //                return;
    //            }
    //            if self.isWaitingForInactivityToStartMicroBreak{
    //                self.breakInactivitySecondsToCheck = 5
    //                self.isWaitingForInactivityToStartMicroBreak = false
    //                self.inActivityStartTime = nil
    //                setFocusBearIconToNormal()
    //            }
    //
    //
    //
    //            isBreakActivityExecuteFromPostponeMorningHabit = false
    //            isBreakActivityExecuteFromPostponeEveningHabit = false
    //
    //            isBreakActivityExecuteFromMorningHabit = false
    //            isBreakActivityExecuteFromEveningHabit = false
    //            checkLogFileRotation()
    //
    //
    //            isBreakActivityShowingWhileMeeting = false
    //            if appdelegate!.isUserOnMeeting{
    //                if !SettingsManagerObject.IsShowBreaksInCallEnabled{
    //                    addLog(text: "isUserOnMeeting True: Break Activities cancelled.")
    //                    self.setActivityTimer()
    //                    isBreakActivityShowingWhileMeeting = false
    //                    return;
    //                }else{
    //                    var anyOfficeFriendlyActivityFound = false
    //                    for activity in arrAllbreakActivities{
    //                        if activity.isOfficeFriendly{
    //                            anyOfficeFriendlyActivityFound = true
    //                            break;
    //                        }
    //                    }
    //                    if !anyOfficeFriendlyActivityFound{
    //                        addLog(text: "User is On Meeting;- no office friendly activity found: Break Activities cancelled.")
    //                        self.setActivityTimer()
    //                        isBreakActivityShowingWhileMeeting = false
    //                        return;
    //                    }
    //                    isBreakActivityShowingWhileMeeting = true
    //                }
    //            }
    //
    //            if isAnyPresentationOrVideoShowing(){
    //                if !SettingsManagerObject.IsShowBreaksInCallEnabled{
    //                    addLog(text: "PresentationOrVideoShowing True: Break Activities cancelled.")
    //                    self.setActivityTimer()
    //                    isBreakActivityShowingWhileMeeting = false
    //                    return;
    //                }else{
    //                    var anyOfficeFriendlyActivityFound = false
    //                    for activity in arrAllbreakActivities{
    //                        if activity.isOfficeFriendly{
    //                            anyOfficeFriendlyActivityFound = true
    //                            break;
    //                        }
    //                    }
    //                    if !anyOfficeFriendlyActivityFound{
    //                        addLog(text: "User is On Meeting;- no office friendly activity found: Break Activities cancelled.")
    //                        self.setActivityTimer()
    //                        isBreakActivityShowingWhileMeeting = false
    //                        return;
    //                    }
    //                    isBreakActivityShowingWhileMeeting = true
    //                }
    //            }
    //
    //            if currentState == ._MORNING_HABIT_{// ⚠️ do not change current state inside this block
    //                // new work // 23/12/22
    //                if currentHabitPlaying != nil && !(mainWindowControllerObj?.window?.isVisible ?? false) && currentAction == ._INPROGRESS_{//it means background morning habit and now break activity is allowed in allowed app morning habit // 23/12/22
    //                    addLog(text: "Morning habit showing, Break Activities allowed in allowed app morning habit.")
    //
    //                    // pause  morning activity and start break activity
    //                    // will not change current state here beacuse we do not want to execute background thread during warning but need to handle when pc goint to sleep during warning
    //                    mainWindowControllerObj?.window?.close()
    //                    hideBlankWindowInSecondaryMonitor()
    //                    isLastActivityStoppedInRunningState = true
    //                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
    //                    isBreakActivityExecuteFromMorningHabit = true
    //
    //                    if timerViewcontrollerObj != nil {
    //                        if timerViewcontrollerObj?.timer != nil {
    //                            timerViewcontrollerObj?.timer?.invalidate()
    //                            enableSystemSleep()
    //                            if timerViewcontrollerObj?.isVideoLodded ?? false{
    //                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
    //                                    timerViewcontrollerObj?.loadBlankUrl()
    //                                }
    //                            }
    //                        }
    //                    }
    //
    //                    if currentHabitPlaying != nil{
    //                        if isAnyAllowedFocusModeActivityRunning{
    //                            closeNudgeFocusAlignmentScoreWindow()
    //                        }
    //                        isAnyAllowedFocusModeActivityRunning = false
    //                        currentHabitPlaying = nil
    //                        refreshFocusModeData()
    //                        setAppIconForFocusModeScore(probability: nil)
    //                        closePupUpBlockIfVisible()
    //
    //                        if smallCountDownWcObj != nil{//
    //                            if smallCountDownWcObj?.window != nil{
    //                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                                    smallCountDownVcObj?.closeTimerBox()
    //                                }
    //                            }
    //                        }
    //                    }
    //
    //                }else{
    //                    addLog(text: "Morning habit showing, Break Activities cancelled.")
    //                    return;
    //                }
    //
    //            }
    //
    //
    //            if currentState == ._EVENING_HABIT_{// ⚠️ do not change current state inside this block
    //
    //                // new work // 23/12/22
    //                if currentHabitPlaying != nil && !(mainWindowControllerObj?.window?.isVisible ?? false) && currentAction == ._INPROGRESS_{//it means background evening habit and now break activity is allowed in allowed app morning habit // 23/12/22
    //                    addLog(text: "Evening habit showing, Break Activities allowed in allowed app Evening habit.")
    //
    //                    // pause  evening activity and start break activity
    //                    // will not change current state here beacuse we do not want to execute background thread during warning but need to handle when pc goint to sleep during warning
    //                    mainWindowControllerObj?.window?.close()
    //                    hideBlankWindowInSecondaryMonitor()
    //                    isLastActivityStoppedInRunningState = true
    //                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
    //                    isBreakActivityExecuteFromEveningHabit = true
    //
    //                    if timerViewcontrollerObj != nil {
    //                        if timerViewcontrollerObj?.timer != nil {
    //                            timerViewcontrollerObj?.timer?.invalidate()
    //                            enableSystemSleep()
    //                            if timerViewcontrollerObj?.isVideoLodded ?? false{
    //                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
    //                                    timerViewcontrollerObj?.loadBlankUrl()
    //                                }
    //                            }
    //                        }
    //                    }
    //
    //                    if currentHabitPlaying != nil{
    //                        if isAnyAllowedFocusModeActivityRunning{
    //                            closeNudgeFocusAlignmentScoreWindow()
    //                        }
    //                        isAnyAllowedFocusModeActivityRunning = false
    //                        currentHabitPlaying = nil
    //                        refreshFocusModeData()
    //                        setAppIconForFocusModeScore(probability: nil)
    //
    //                        closePupUpBlockIfVisible()
    //
    //                        if smallCountDownWcObj != nil{//
    //                            if smallCountDownWcObj?.window != nil{
    //                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
    //                                    smallCountDownVcObj?.closeTimerBox()
    //                                }
    //                            }
    //                        }
    //                    }
    //
    //
    //                   // //////////////
    //                }else{
    //                    addLog(text: "Evening habit showing, Break Activities cancelled.")
    //                    return;
    //                }
    //
    //            }
    //
    //            self.reFillBreakActivitiesArray()
    //            if arrFinalBreakActivities.count == 0{
    //                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
    //                self.setActivityTimer()//possible nahi hai
    //                return;
    //            }
    //            if currentState == ._POSTPON_MORNING_HABIT_{// ⚠️ do not change current state inside this block
    //                // new work // 20/04/23
    //                if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                    isBreakActivityExecuteFromPostponeMorningHabit = true// morning habit postpone over hua to activity timer bhi band hoga or agar activity chal rhi hui to vo bhi band hokar uska timer band hoga
    //                }else{
    //                    return;
    //                }
    //            }
    //
    //            if currentState == ._POSTPON_EVENING_HABIT_{// ⚠️ do not change current state inside this block
    //                if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                    isBreakActivityExecuteFromPostponeEveningHabit = true
    //                }else{
    //                    return;
    //                }
    //            }
    //
    //            if currentState == ._POSTPON_FOCUS_SUMMARY_{// ⚠️ do not change current state inside this block
    //                if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
    //                    isBreakActivityExecuteFromPostponeEveningHabit = true
    //                }else{
    //                    return;
    //                }
    //            }
    //
    //            self.removeSubViews()
    //
    //            showBreakWarningWindow()
    //            currentState = ._MICRO_BREAK_
    //            currentAction = ._START_// added on 24/7/25 v 1.26.394
    //            shouldShowPomodoroAfterBreak = false
    //        }
    //    }
    
    //    func reFillBreakActivitiesArray(){
    //        var isAnyMandatoryActivityIncluded = false
    //        var arrActivitiesIncludeInEveryBreak = [breakActivity]()
    //        var arrActivitiesExcludeInEveryBreak = [breakActivity]()
    ////        isMandatoryActivityGoing = false
    //
    //        for activity in arrAllbreakActivities{
    //            if isBreakActivityShowingWhileMeeting{
    //                if !activity.isOfficeFriendly{
    //                    continue;
    //                }
    //            }else{
    //                if SettingsManagerObject.isOfficeModeEnabled{
    //                    if !activity.isOfficeFriendly{
    //                        continue;
    //                    }
    //                }
    //            }
    //            if activity.IncludeInEveryBreak{
    //                isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory arra than normal array
    //                arrActivitiesIncludeInEveryBreak.append(activity)
    //            }else{
    //                arrActivitiesExcludeInEveryBreak.append(activity)
    //            }
    //        }
    //        //                checking if  Office Mode is on and if there is not any activity office friendly than turn off office mode
    //        if SettingsManagerObject.isOfficeModeEnabled{
    //            if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
    //                addLog(text: "SettingsManagerObject.isOfficeModeEnabled false becuse no office friendly activity found.")
    //                SettingsManagerObject.isOfficeModeEnabled = false
    //                NSApplication.shared.applicationIconImage = nil
    //                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsOfficeModeEnabled)
    //
    //                SettingsManagerObject.isSettingsChanged = true
    //                SettingsManagerObject.putUserLocalDeviceSettings()
    //
    //
    //                for activity in arrAllbreakActivities{
    //                    if activity.IncludeInEveryBreak{
    //                        isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory array than normal array
    //                        arrActivitiesIncludeInEveryBreak.append(activity)
    //                    }else{
    //                        arrActivitiesExcludeInEveryBreak.append(activity)
    //                    }
    //                }
    //
    //            }
    //        }
    //        arrFinalBreakActivities.removeAll()//Tell user what break activities are coming up#479
    //        if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
    //            //addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
    //            //self.setActivityTimer()//possible nahi hai
    //            return;
    //        }
    //
    //        currentActivityIndex = -1
    //        if isAnyMandatoryActivityIncluded{
    ////            isMandatoryActivityGoing = true//
    //            for activity in arrActivitiesIncludeInEveryBreak{
    //                arrFinalBreakActivities.append(breakActivityFilter(activity: activity, randomChoice: nil))
    //            }
    //
    //            if arrActivitiesExcludeInEveryBreak.count != 0{
    //                let randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
    //                arrFinalBreakActivities.append(breakActivityFilter(activity: arrActivitiesExcludeInEveryBreak[randomActivityIndex], randomChoice: nil))
    //            }
    //        }else{
    //            let randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
    ////            randomActivityIndex = currentActivityIndex
    //            arrFinalBreakActivities.append(breakActivityFilter(activity: arrActivitiesExcludeInEveryBreak[randomActivityIndex], randomChoice: nil))
    //        }
    //        //
    //
    //
    //        for i in 0..<arrFinalBreakActivities.count{//
    //            let filterActivity = arrFinalBreakActivities[i]
    //            if let currentActivity = filterActivity.activity{
    //                if currentActivity.choiceType == ._RANDOM_{
    //                    var currentActivityChoice = currentActivity.choices.randomElement()
    //
    //                    if currentActivity.choices.count != 1{
    //                        if let lastChoice = lastShownRandomChoiceDic[currentActivity.id]{
    //                            while lastChoice.id == currentActivityChoice!.id {
    //                                currentActivityChoice = currentActivity.choices.randomElement()
    //                            }
    //                        }
    //                    }
    //                    lastShownRandomChoiceDic[currentActivity.id ?? ""] = currentActivityChoice
    //                    arrFinalBreakActivities[i].randomChoice = currentActivityChoice
    //                }
    //            }
    //        }
    //        //--------------------------------------------------------------------//
    //        //After the 7 day free trial, let's allow users to downgrade to Free Basic.//Support freemium#1066
    //        //if ap is expired max 5 habits in the morning and evening routines (if the user has more than 5, only show the first 5)#1066
    //        isActivitiesReducedInExpiredApp = false
    //        if isExpired{
    //            if arrFinalBreakActivities.count > activitiesCountInExpireApp{
    //                isActivitiesReducedInExpiredApp = true
    //                let arrTempBreakActivities = arrFinalBreakActivities
    //                arrFinalBreakActivities.removeAll()
    //                for i in 0..<activitiesCountInExpireApp{
    //                    arrFinalBreakActivities.append(arrTempBreakActivities[i])
    //                }
    //            }
    //        }
    //        //----------------------------------------------------------------------//
    //    }
    
    //    @objc func executeBreakActivities() {//   is any this is new in this func  we should also review this fucc "okClickedFromCustomMessage()"{
    //        shouldShowPomodoroAfterBreak = false
    //        isBreakActivityShowingWhileMeeting = false
    //        addLog(text: "startBreakActivities")
    //        stopActivityTimer()
    //        if arrAllbreakActivities.count != 0 {
    //
    //            reFillBreakActivitiesArray()
    //
    //            if arrFinalBreakActivities.count == 0{
    //                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
    //                self.setActivityTimer()//possible nahi hai
    //                return;
    //            }
    //
    //            self.removeSubViews()
    //            currentState = ._MICRO_BREAK_
    //
    //
    //            self.performBreakActivities()
    //
    //        }
    //
    //    }
    //    func enableOfficeModeAndRestartBreakActivities(){
    //        addLog(text: "enableOfficeModeAndRestartBreakActivities")
    //        var officeModeEnableText = "Ok I'll give you some break activities that are appropriate to do in an office environment."
    //
    //        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
    //            officeModeEnableText = activityPostponeInfo.value(forKey: "officeModeEnableText") as? String ?? officeModeEnableText
    //        }
    //
    //        showCustomMessageView(msg: officeModeEnableText)
    //    }
    func showCustomMessageView(msg:String){
        addLog(text: "show Custom Message View")
        self.view.addSubview(getCustomMessageVcObject().view)
        self.view.addConstraints(subView: getCustomMessageVcObject().view)
        customMessageVcObj?.lblMessage.stringValue = msg
    }
    
    //    func okClickedFromCustomMessage(){
    //        addLog(text: "ok Clicked From CustomMessage")
    //        addLog(text: "enableOfficeMode from postpone nag")//
    //        SettingsManagerObject.isOfficeModeEnabled = true
    //        allApiObject.capturePosthog(event: "enable-office-mode", metadata: [:])
    //        SettingsManagerObject.isSettingsChanged = true
    //        SettingsManagerObject.putUserLocalDeviceSettings()
    //        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
    //        NSApplication.shared.applicationIconImage = NSImage(named: NSImage.Name("Bear-Office-icon"))
    //
    //
    //        reFillBreakActivitiesArray()
    //        self.removeSubViews()
    //        currentState = ._MICRO_BREAK_
    //
    //        if currentAction == ._BRAIN_DUMP_{
    //            addLog(text: "ok Clicked From Custom Message:- performBreakActivities break activity ")
    //            self.performBreakActivities()
    //        }else{
    //            addLog(text: "ok Clicked From Custom Message:- list break activity ")
    //            self.showCloseButtons()
    //            thirdVcObj?.startBreakActivity()
    //            showBreakActivityListView()
    //        }
    //    }
    
    //    func performBreakActivities(){
    //        addLog(text: "perform Break Activities")
    //        self.showCloseButtons()
    //        postponeBreaksFromBreaksWarningCount = 0
    //        if brainDumpWcObj != nil{
    //            if brainDumpWcObj!.window?.isVisible ?? false{
    //                brainDumpWcObj?.window?.close()
    //            }
    //        }
    //        if !(thirdVcObj?.isViewLoaded ?? false){
    //            thirdVcObj?.loadView()
    //        }
    //        thirdVcObj?.startBreakActivity()
    //        mainWindowControllerObj?.window?.setIsVisible(true)
    //        showBlankWindowInSecondaryMonitor()
    //
    //
    //        if isBreakActivityShowingWhileMeeting{
    //            showBreakActivityListView()
    //        }else{
    //            currentAction = ._BRAIN_DUMP_//new work #502
    //            showBreaksBrainDump()
    //        }
    //        shouldShowPomodoroAfterBreak = false
    //        NSApplication.shared.activate(ignoringOtherApps: true)
    //    }
    
    //    func showBreakActivityListView(){
    //        addLog(text: "showBreakActivityListView")
    //        currentAction = ._START_//new work #502
    //        self.removeSubViews()
    //        firstViewControllerObj?.isFirstTime = false
    //        containerView.addSubview(firstViewControllerObj!.view)
    //        containerView.addConstraints(subView: firstViewControllerObj!.view)
    //        firstViewControllerObj?.tblViewHabits.reloadData()
    //    }
    
    @IBAction func btnHiddenClicked(_ sender: Any) {
        //mainWindowControllerObj?.window?.close()
    }
    
    func askPasswordForSettingsIfNeeded(){
        if isPasswordRequireInOpenSettings(){
            askPasswordForSettings()
        }
    }
    
    func askPasswordForSettings(){
        self.view.addSubview(getEnterPasswordVcObjForPreferences().view)
        self.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
        getEnterPasswordVcObjForPreferences().parentVc = nil
        enterPasswordVcObjForPreferences?.removeConstraints()
        addLog(text: "Showing enter password view inside edit habits")
    }
    
    func isEnterPasswordForPreferencesViewVisible()->Bool{
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(getEnterPasswordVcObjForPreferences().view){
                return true
            }
        }
        return false
    }

    func showHabitsView(){
        self.removeSubViews()
        containerView.addSubview(getHabitsVcObject().view)
        containerView.addConstraints(subView: getHabitsVcObject().view)
    }
    
    func showFocusSessionView(pomodoroView:NSView){
        self.removeSubViews()
        containerView.addSubview(pomodoroView)
        containerView.addConstraints(subView: pomodoroView)
    }
    
    func showBrainDumpView(){
        self.removeSubViews()
        containerView.addSubview(getBrainDumpVcObject().view)
        containerView.addConstraints(subView: getBrainDumpVcObject().view)
    }
    
    func showAllTracksView(){
        self.removeSubViews()
        containerView.addSubview(getAllTracksVcObj().view)
        containerView.addConstraints(subView: getAllTracksVcObj().view)
    }
    
    func showTaskView(){
        self.removeSubViews()
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
            containerView.addSubview(taskPlayerVcObj!.view)
            containerView.addConstraints(subView: taskPlayerVcObj!.view)
            if shouldReloadTaskPlayer{
                shouldReloadTaskPlayer = false
                taskPlayerVcObj?.reloadData(totalDuration: focusModeMinutesToPerform, intention:whatToAchieveInFocusBlock)
            }else{
                taskPlayerVcObj?.reloadView()
            }
        }else{
            containerView.addSubview(getTodoListToolVcObject().view)
            containerView.addConstraints(subView: getTodoListToolVcObject().view)
            todoListToolVcObj?.reloadData()
        }
    }
    
    func showFocusCompletedView(){
        self.removeSubViews()
        containerView.addSubview(focusCompletedVcObj!.view)
        containerView.addConstraints(subView: focusCompletedVcObj!.view)
    }
    
    func showFocusAbortedView(){
        self.removeSubViews()
        containerView.addSubview(abortingFocusModeVcObj!.view)
        containerView.addConstraints(subView: abortingFocusModeVcObj!.view)
    }
    
    
    func showDashboardView(){
        self.removeSubViews()
        containerView.addSubview(getSetUpVcObject().view)
        containerView.addConstraints(subView: getSetUpVcObject().view)
        if getSetUpVcObject().widthConstraint != nil{
            getSetUpVcObject().widthConstraint.isActive = false
        }
    }
    
    func showMotivationView(){
        self.removeSubViews()
        containerView.addSubview(getSetUpVcObject().view)
        containerView.addConstraints(subView: getSetUpVcObject().view)
        if getSetUpVcObject().widthConstraint != nil{
            getSetUpVcObject().widthConstraint.isActive = false
        }
    }
    
    func showFocusModeState(){
        addLog(text: "showFocusModeState")
        self.removeSubViews()
        containerView.addSubview(getFocusModeStateVcObject().view)
        containerView.addConstraints(subView: getFocusModeStateVcObject().view)
    }
    
    func showHelpView(){
        self.removeSubViews()
        containerView.addSubview(getHelpVcObject().view)
        containerView.addConstraints(subView: getHelpVcObject().view)
    }
    //getTabStrictnessContainerVcObject  getFocusPreferencesVcObject getSettingsSplitViewControllerObject getSelectJsonVcObject

    func showBlocksPreferencesView(){
        self.removeSubViews()
        containerView.addSubview(getTabStrictnessContainerVcObject().view)
        containerView.addConstraints(subView: getTabStrictnessContainerVcObject().view)
    }
    
    func showFocusPreferencesView(){
        self.removeSubViews()
        containerView.addSubview(getFocusPreferencesVcObject().view)
        containerView.addConstraints(subView: getFocusPreferencesVcObject().view)
    }
    
    func showSettingsView(){
        self.removeSubViews()
        containerView.addSubview(getSettingsSplitViewControllerObject().view)
        containerView.addConstraints(subView: getSettingsSplitViewControllerObject().view)
    }
    
    func showEditHabitsView(){
        self.removeSubViews()
        containerView.addSubview(getSelectJsonVcObject().view)
        containerView.addConstraints(subView: getSelectJsonVcObject().view)
    }
    
    func toggleLeftPaneWidth(){
        guard splitView.subviews.count >= 2 else { return }
        let leftView = splitView.subviews[0]
        if leftView.frame.width == 50{
            expandLeftPanel()
        }else{
            collapseLeftPanel()
        }
    }
    
    func expandLeftPanel(){
        setLeftPaneWidthTemporarily(to: 230)
    }
    
    func collapseLeftPanel(){
        setLeftPaneWidthTemporarily(to: 50)
    }
    
    private var leftWidthConstraint: NSLayoutConstraint?

    func setLeftPaneWidthTemporarily(to newWidth: CGFloat) {
        guard splitView.subviews.count >= 2 else { return }

        let leftView = splitView.subviews[0]

        // Remove any previous constraint first
        if let existing = leftWidthConstraint {
            existing.isActive = false
            leftView.removeConstraint(existing)
            leftWidthConstraint = nil
        }

        // Disable autoresizing mask
        leftView.translatesAutoresizingMaskIntoConstraints = false

        // Create temporary width constraint
        let constraint = leftView.widthAnchor.constraint(equalToConstant: newWidth)
        constraint.priority = .required
        constraint.isActive = true
        leftWidthConstraint = constraint

        // Animate change
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            splitView.layoutSubtreeIfNeeded()
        }, completionHandler: {
            // Remove constraint so user can drag again
            if let existing = self.leftWidthConstraint {
                existing.isActive = false
                leftView.removeConstraint(existing)
                self.leftWidthConstraint = nil
            }
            leftView.translatesAutoresizingMaskIntoConstraints = true
            self.splitView.adjustSubviews()
        })
    }


}
