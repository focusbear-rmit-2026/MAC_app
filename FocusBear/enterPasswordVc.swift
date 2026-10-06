//
//  enterPasswordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class enterPasswordVc: NSViewController, NSTextFieldDelegate {
   
    @IBOutlet weak var customViewAccountabilityBuddy: NSView!
    @IBOutlet weak var mainView: NSView!
    
    @IBOutlet weak var blockingView: BlockingView!
    @IBOutlet weak var bgButton: NSButton!
    @IBOutlet weak var topBox: NSLayoutConstraint!
    @IBOutlet weak var bottombox: NSLayoutConstraint!
    @IBOutlet weak var leadingBox: NSLayoutConstraint!
    @IBOutlet weak var trailingBox: NSLayoutConstraint!
    @IBOutlet weak var textFieldRandomString: NSTextField!
    @IBOutlet weak var lblRandomString: NSTextField!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var tabViewItemEnterCharacters: NSTabViewItem!
    @IBOutlet weak var tabViewItemPassword: NSTabViewItem!
    @IBOutlet weak var tabViewItemAccountabilityBuddy: NSTabViewItem!
    
    
    
    @IBOutlet weak var lblError: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var textFieldPassword: NSSecureTextField!
    @IBOutlet weak var btnResetPassword: underLineButton!
    @IBOutlet weak var btnOk: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    
    @IBOutlet weak var stackViewTitle: NSStackView!
    @IBOutlet weak var stackViewTextField: NSStackView!
    
    var isCurrentViewInMainWindow = false
    var buttonResetPasswordText = "Reset Password"
    var randomCharacters = ""
    var parentVc:NSViewController?
    var isShowingForRelaxFocusMode = false
    var isShowingForDeactivatingApp = false
    
    var pendingAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    
    var accountabilityBuddyVcObj:accountabilityBuddyVc?
    func getAccountabilityBuddyVcObject()->accountabilityBuddyVc{
        if accountabilityBuddyVcObj == nil{
            accountabilityBuddyVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("accountabilityBuddyVc")) as? accountabilityBuddyVc
        }
        return accountabilityBuddyVcObj!
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        trailingBox.p
        textFieldRandomString.isHidden = true
        lblRandomString.isHidden = true
        lblTitle.stringValue = "Please enter the password to continue"
        textFieldPassword.placeholderString = "Password"
        tabViewItemPassword.label = "Enter password"
        tabViewItemEnterCharacters.label = "Type random characters"
        textFieldRandomString.placeholderString = "Type random characters"

        tabViewItemAccountabilityBuddy.label = "Accountability Buddy"
        
        
        if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
            if let title = enterPasswordViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let passwordPlaceholderText = enterPasswordViewInfo.value(forKey: "passwordPlaceholderText") as? String{
                textFieldPassword.placeholderString = passwordPlaceholderText
            }
            if let buttonResetPasswordText = enterPasswordViewInfo.value(forKey: "buttonResetPasswordText") as? String{
                self.buttonResetPasswordText = buttonResetPasswordText
            }
            
            tabViewItemPassword.label = enterPasswordViewInfo.value(forKey: "tabViewPasswordTitle") as? String ?? tabViewItemPassword.label
            tabViewItemEnterCharacters.label = enterPasswordViewInfo.value(forKey: "tabViewRandomCharactersTitle") as? String ?? tabViewItemEnterCharacters.label
            textFieldRandomString.placeholderString = enterPasswordViewInfo.value(forKey: "tabViewRandomCharactersTitle") as? String ?? textFieldRandomString.placeholderString
            
            tabViewItemAccountabilityBuddy.label = enterPasswordViewInfo.value(forKey: "tabViewAccountabilityBuddyTitle") as? String ?? tabViewItemAccountabilityBuddy.label
        }
        btnResetPassword.title = buttonResetPasswordText
        
        btnOk.title = buttonOkText//"OK"
        btnCancel.title = buttonCancelText//"Cancel"
        textFieldPassword.delegate = self
        btnResetPassword.isHidden = true
        tabView.delegate = self
        customViewAccountabilityBuddy.isHidden = true
        
    }
    
    func requestAuthorization(action: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        pendingAction = action
        cancelAction = onCancel
    }
    
    func hidePasswordView(){
        stackViewTextField.isHidden = true
        stackViewTitle.isHidden = true
        btnOk.isHidden = true
        btnCancel.isHidden = true
        lblError.isHidden = true
    }
    
    func showPasswordView(){
        stackViewTextField.isHidden = false
        stackViewTitle.isHidden = false
        btnOk.isHidden = false
        btnCancel.isHidden = false
        
        lblError.isHidden = true// keep it true
    }
    
    
    func removeConstraints(){
        if topBox != nil{
            mainView.removeConstraint(topBox)
            mainView.removeConstraint(bottombox)
            mainView.removeConstraint(leadingBox)
            mainView.removeConstraint(trailingBox)
        }
    }
    
    override func viewWillAppear() {
        isCurrentViewInMainWindow = false
        lblError.isHidden = true
        lblError.stringValue = ""
        textFieldPassword.stringValue = ""
        textFieldRandomString.stringValue = ""
        //btnResetPassword.isHidden = false
        
        if UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) == nil{//if reset is in progress then disable reset button
            btnResetPassword.setEnable(title: buttonResetPasswordText)
        }else{
            btnResetPassword.setDisable(title: buttonResetPasswordText)
        }
        
        if isMainWindowLoaded{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                isCurrentViewInMainWindow = true
            }
        }
        //If user click stop, it can prompt for the password. If no password is set, it can prompt for the random characters.// added in v 2.27.420 // 27/9/25
        if !SettingsManagerObject.isAppPasswordSet{
            tabView.selectTabViewItem(tabViewItemEnterCharacters)
        }else{
            tabView.selectTabViewItem(tabViewItemPassword)
        }
    }
    
    override func viewWillDisappear() {
        // Hide password dialogue from screenshots  #1276  // reset after password view removes
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
    }
    
    override func viewDidDisappear() {
        
    }
    
    override func viewDidAppear() {
        textFieldPassword.selectText(self)
        textFieldPassword.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        
        //Hide password dialogue from screenshots  #1276
        self.view.window?.sharingType = .none 
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        addLog(text: "[user-action] Enter password view - btnOkClicked")//
        
        if tabView.selectedTabViewItem == tabViewItemEnterCharacters{
            if textFieldRandomString.stringValue == randomCharacters{
                addLog(text: "Enter password view - random characters are correct")//
                allApiObject.capturePosthog(event: "unlock-using-random-chars", metadata: [:])
                authenticated()
            }else{
                addLog(text: "Enter password view - invalid random characters")//
                var blankCharactersErrorTitle = "Entered characters does not match the required characters. Please try again."
                if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                    blankCharactersErrorTitle = enterPasswordViewInfo.value(forKey: "incorrectCharactersErrorTitle") as? String ?? blankCharactersErrorTitle
                }
                if isCurrentViewInMainWindow{
                    lblError.isHidden = false
                    lblError.stringValue = "\(blankCharactersErrorTitle)"
                }else{
                   alertforvalidation(question: blankCharactersErrorTitle, text: "")
                }
                return;
            }
        }else{
            if textFieldPassword.stringValue.isEmpty{
                var blankPasswordErrorTitle = "Password cannot be blank."
                var blankPasswordErrorSubTitle = "Please enter a valid password."
                
                
                if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                    if let title = enterPasswordViewInfo.value(forKey: "blankPasswordErrorTitle") as? String{
                        blankPasswordErrorTitle = title
                    }
                    if let title = enterPasswordViewInfo.value(forKey: "blankPasswordErrorSubTitle") as? String{
                        blankPasswordErrorSubTitle = title
                    }
                }
                
                if isCurrentViewInMainWindow{
                    lblError.isHidden = false
                    lblError.stringValue = "\(blankPasswordErrorTitle) \(blankPasswordErrorSubTitle)"
                }else{
                   alertforvalidation(question: blankPasswordErrorTitle, text: blankPasswordErrorSubTitle)
                }
                return;
            }
            
            if SettingsManagerObject.isAppPasswordSet{
                if SettingsManagerObject.appPassword.matches(textFieldPassword.stringValue){
                    addLog(text: "Enter password view - password is correct")//
                    lastAppUnlockTime = Date()
                    allApiObject.capturePosthog(event: "unlock-using-password", metadata: [:])
                    authenticated()
                }else{
                    addLog(text: "Enter password view - Invalid password.")//
                    var alertTitle = "Invalid password."
                    if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                        if let title = enterPasswordViewInfo.value(forKey: "incorrectPasswordErrorTitle") as? String{
                            alertTitle = title
                        }
                    }
                    if isCurrentViewInMainWindow{
                        lblError.isHidden = false
                        lblError.stringValue = alertTitle
                    }else{
                       alertforvalidation(question: alertTitle, text: "")
                    }
                }
            }
        }
    }
    
    func authenticated(){
        if let pendingAction = pendingAction{
            self.view.removeFromSuperview()
            pendingAction()
            self.pendingAction = nil
            self.cancelAction = nil
            return;
        }
        if parentVc != nil{
            
            if parentVc == pomodoroVcObj{
                self.dismiss(self)
                let totalMinutes = pomodoroVcObj!.workDurationMinutes
                if currentState == ._POSTPONE_MORNING_HABIT_ && !isShowingForRelaxFocusMode{
                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                    pomodoroVcObj!.checkStateAndStartPomodoroMode()
                }else if currentState == ._POSTPONE_EVENING_HABIT_ && !isShowingForRelaxFocusMode{
                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                    pomodoroVcObj!.checkStateAndStartPomodoroMode()
                }else if currentState == ._POSTPONE_FOCUS_SUMMARY_ && !isShowingForRelaxFocusMode{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                    pomodoroVcObj!.checkStateAndStartPomodoroMode()
                }else if isShowingForRelaxFocusMode{
                    pomodoroVcObj!.pomodoroModeStarted()
                    
                    
                    if currentState != ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
                        
                        pomodoroVcObj?.view.window?.close()//  will not work if view has changed (task player is viisble now). because if main view is changes then window is nil.no need to change anything
                    }else{
                        leftMenuVcObj?.showBreaksView()
                    }
                }
                isShowingForRelaxFocusMode = false
                return;
            }else if parentVc == focusEndWarningVcObj{
                self.dismiss(self)
                let totalMinutes = FocusSessionExtension.cutoffLimitedMinutes(Int(focusEndWarningVcObj?.popUpBtn.title ?? "1") ?? 0, from: endFocusModeTime)
                guard totalMinutes > 0 else { return }
                if currentState == ._POSTPONE_MORNING_HABIT_{
                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if currentState == ._POSTPONE_EVENING_HABIT_{
                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if currentState == ._POSTPONE_FOCUS_SUMMARY_{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                }
                focusEndWarningVcObj!.extendFocusMode()
                return;
            }else if parentVc == addTaskVcObj{
                self.dismiss(self)
                let totalMinutes = FocusSessionExtension.cutoffLimitedMinutes(addTaskVcObj?.extensionMinutesForPostpone ?? 0, from: nil)
                guard totalMinutes > 0 else { return }
                // Fall back to the persisted last-postpone state: when extending from the completion
                // popup the covering focus session has already finished, so currentState is ._NOTHING_
                // and these live checks would all miss — leaving the habits un-covered (#2213).
                let postponeState = routinePostponeStateToReCoverOnExtend() ?? currentState
                if postponeState == ._POSTPONE_MORNING_HABIT_{
                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if postponeState == ._POSTPONE_EVENING_HABIT_{
                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if postponeState == ._POSTPONE_FOCUS_SUMMARY_{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                }
                addTaskVcObj?.extendFocusMode()
                return;
            }else if parentVc == simplePomodoroVcObj{
                self.dismiss(self)
                let totalMinutes = simplePomodoroVcObj!.workDurationMinutes
                getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                simplePomodoroVcObj!.pomodoroModeStarted()
                
                if currentState != ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
                    
                    simplePomodoroVcObj?.view.window?.close()//  will not work if view has changed (task player is viisble now). because if main view is changes then window is nil.no need to change anything
                }else{
                    leftMenuVcObj?.showBreaksView()
                }
                return;
            }else if parentVc == menuViewControllerObj{
                self.view.window?.close()
                menuViewControllerObj?.passwordIsCorrect()
                customUrlHandleLastDurationForRelaxFocusMode = 0
                return;
            }else if parentVc == pomodoroVcObj{
                self.view.window?.close()
                pomodoroVcObj?.passwordIsCorrect()
                return;
            }else if parentVc == getAskPostponeVcObject(){
                
                if lastCurrentState == ._MORNING_HABIT_{// //
                    var postponeTime = 0
                    if askPostponeVcObj != nil{
                        if askPostponeVcObj!.popUpButtonSelectMinutes != nil{
                            postponeTime = Int(askPostponeVcObj!.popUpButtonSelectMinutes.title) ?? 15
                        }
                    }
                    if activityPostponeCount == 0 && postponeTime > 15{
                        activityPostponeCount += 1
                        self.view.removeFromSuperview()
                        getHabitsVcObject().postponeMorningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                        return;
                    }else{
                        self.view.removeFromSuperview()
                        // The password was the gate — don't also make them hold the countdown.
                        getAskPostponeVcObject().hasSatisfiedPostponePassword = true
                        getHabitsVcObject().showAskPostponeView()
                        return;
                    }


                }else if lastCurrentState == ._EVENING_HABIT_{
                    // Evening uses the hold-to-set control, so read the minutes it resolved
                    // rather than the (now hidden) dropdown title.
                    var postponeTime = 0
                    if let resolvedEveningMinutes = askPostponeVcObj?.resolvedEveningPostponeMinutes{
                        postponeTime = resolvedEveningMinutes
                    }else if askPostponeVcObj?.popUpButtonSelectMinutes != nil{
                        postponeTime = Int(askPostponeVcObj!.popUpButtonSelectMinutes.title) ?? 15
                    }
                    if activityPostponeCount == 0 && postponeTime > 15{
                        activityPostponeCount += 1
                        self.view.removeFromSuperview()
                        getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                        return;
                    }else{
                        self.view.removeFromSuperview()
                        // The password was the gate — don't also make them hold the countdown.
                        getAskPostponeVcObject().hasSatisfiedPostponePassword = true
                        getHabitsVcObject().showAskPostponeView()
                        return;
                    }


                }else if lastCurrentState == ._FOCUS_SUMMARY_{
                    self.view.window?.close()
                    self.view.removeFromSuperview()

                    if askPostponeVcObj != nil{
                        if askPostponeVcObj!.popUpButtonSelectMinutes != nil{
                            getHabitsVcObject().postponeFocusSummaryFor(minutes: Int(askPostponeVcObj!.popUpButtonSelectMinutes.title) ?? 15, showAskIntention: true)
                        }else{
                            getHabitsVcObject().postponeFocusSummaryFor(minutes: 15, showAskIntention: true)
                        }
                    }else{
                        getHabitsVcObject().postponeFocusSummaryFor(minutes: 15, showAskIntention: true)
                    }
                    return;
                }
                
            }else if parentVc == firstViewControllerObj{
                self.view.removeFromSuperview()
                firstViewControllerObj?.passWordAuthenticated()
                return;
            }
            
            if easyPostponeVcObj != nil{
                if self.parentVc == easyPostponeVcObj!{
                    if !isShowingForDeactivatingApp{
                        self.dismiss(self)
                        return;
                    }else{
                        self.dismiss(self)
                        easyPostponeVcObj?.deactivateApp()
                        return;
                    }
                }
            }
            
            if skipHabitVcObj != nil{
                if parentVc == skipHabitVcObj!{
                    self.view.removeFromSuperview()
                    getHabitsVcObject().showSkipHabitView()
                    return;
                }
            }
            
            if whySkipHabitVcObj != nil{
                if parentVc == whySkipHabitVcObj!{
                    self.view.removeFromSuperview()
                    whySkipHabitVcObj?.skipActivityAlreadyDid()
                    return;
                }
            }
        }
                            
        if isMainWindowLoaded{
            if self.view.window == mainWindowControllerObj?.window{
                if (mainWindowControllerObj?.window!.isVisible)!{//it means isi per aaya hoga
                    
                    if (leftMenuVcObj?.boxBlocks.isSelected ?? false) || (leftMenuVcObj?.boxSettings.isSelected ?? false) || (leftMenuVcObj?.boxEditHabits.isSelected ?? false){
                        
                        if leftMenuVcObj?.boxSettings.isSelected ?? false{
                            if frictionVcObj != nil{
                                if settingsContainerVcObj?.containerView.subviews.contains(frictionVcObj!.view) ?? false{
                                    if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
                                        self.view.removeFromSuperview()
                                        frictionVcObj?.turnOffReloadAfterForceQuit()
                                        return;
                                    }
                                }
                            }
                            if uIVcObj != nil{
                                if settingsContainerVcObj?.containerView.subviews.contains(uIVcObj!.view) ?? false{
                                    if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
                                        self.view.removeFromSuperview()
                                        uIVcObj?.settingsChangegShowDockIcon()
                                        return;
                                    }
                                }
                            }
                        }
                        
                        
                        self.view.removeFromSuperview()
                        return;
                    }else{
                        self.view.removeFromSuperview()
                        if currentState == ._FOCUS_SUMMARY_{
                            focusSummaryVcObj?.postponeFocusSummaryForOneMinute()
                        }else if currentState == ._SHUTOFFMAC_{
                            shutOffTimeVcObj!.passwordEnteredSuccessfully()
                        }else{
                            getHabitsVcObject().showAbortStartView()
                        }
                    }
                    return;
                }
            }
        }
        
        if quittingWcObj != nil{//postpone cancel from password box
            if self.view.window == quittingWcObj?.window{
                if quittingWcObj?.contentViewController == askQuitVcObj{
                    if isShowingForDeactivatingApp{
                        self.view.removeFromSuperview()
                        askQuitVcObj?.tryDeactivateApp()
                    }else{
                        askQuitVcObj?.postponeHabits()
                        self.view.removeFromSuperview()
                    }
                    return;
                }
            }
        }
        if quittingWcObj != nil{
            if self.view.window == getQuittingWindowObject().window{
                self.view.removeFromSuperview()
                return;
            }
        }
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                if self.presentingViewController == popupAppointmentTimeVcObj{
                    self.dismiss(self)
                    popupAppointmentTimeVcObj?.startAppointment()
                    return;
                }
            }
        }
        self.view.removeFromSuperview()
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "[user-action] Enter password view - cancel clicked")
        allApiObject.capturePosthog(event: "cancel-when-prompted-password", metadata: [:])
        
        if let cancelAction = cancelAction{
            self.view.removeFromSuperview()
            cancelAction()
            self.pendingAction = nil
            self.cancelAction = nil
            return;
        }
        
        if parentVc != nil{
            if parentVc == pomodoroVcObj{
                self.dismiss(self)
                isShowingForRelaxFocusMode = false
                return;
            }else if parentVc == focusEndWarningVcObj{
                self.dismiss(self)
                focusEndWarningVcObj?.extendFocusMode()
                return;
            }else if parentVc == addTaskVcObj{
                self.dismiss(self)
                addTaskVcObj?.extendFocusMode()
                return;
            }else if parentVc == menuViewControllerObj{
                customUrlHandleLastDurationForRelaxFocusMode = 0
                self.view.window?.close()
                return;
            }else if parentVc == pomodoroVcObj{
                self.view.window?.close()
                return;
            }else if parentVc == getAskPostponeVcObject(){
                self.view.removeFromSuperview()
                getHabitsVcObject().abortCancel()
                return;
            }else if parentVc == firstViewControllerObj{
                self.view.removeFromSuperview()
                // Clicking Done/Skip hid the routine action buttons before prompting for the password;
                // cancelling must bring them back. Re-render the Day Plan routine cards (and the habit
                // list's action bar) so the Done button reappears.
                firstViewControllerObj?.refreshScheduleIfVisible()
                if let tbl = firstViewControllerObj?.tblViewHabits {
                    let sel = tbl.selectedRow
                    tbl.reloadData()
                    if sel >= 0 { tbl.selectRowIndexes(IndexSet(integer: sel), byExtendingSelection: false) }
                }
                return;
            }
            
            if skipHabitVcObj != nil{
                if parentVc == skipHabitVcObj!{
                    self.view.removeFromSuperview()
                    return;
                }
            }
            if whySkipHabitVcObj != nil{
                if parentVc == whySkipHabitVcObj!{
                    self.view.removeFromSuperview()
                    return;
                }
            }
            if easyPostponeVcObj != nil{
                if self.parentVc == easyPostponeVcObj{
                    if !isShowingForDeactivatingApp{
//                        easyPostponeWcObj?.window?.close()
                        closeEasyPostponeWindowIfVisible()
                        return;
                    }else{
                        self.dismiss(self)
                        return;
                    }
                }
            }
        }
        
        if isMainWindowLoaded{
            if self.view.window == mainWindowControllerObj?.window{
                if (mainWindowControllerObj?.window!.isVisible)!{//
                    
                    
                    
                    if (leftMenuVcObj?.boxBlocks.isSelected ?? false) || (leftMenuVcObj?.boxSettings.isSelected ?? false) || (leftMenuVcObj?.boxEditHabits.isSelected ?? false){
                        if passwordVcObj != nil{
                            if settingsContainerVcObj?.containerView.subviews.contains(passwordVcObj!.view) ?? false{
                                if !SettingsManagerObject.isPasswordRequireInChangeSettings{
                                    self.view.removeFromSuperview()
                                    passwordVcObj?.btnBackClicked(self)
                                    return;
                                }
                            }
                        }
                        if leftMenuVcObj?.boxSettings.isSelected ?? false{
                            
                            if frictionVcObj != nil{
                                if settingsContainerVcObj?.containerView.subviews.contains(frictionVcObj!.view) ?? false{
                                    if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
                                        self.view.removeFromSuperview()
                                        frictionVcObj?.reloadAppAfterForceQuitItemVcObj?.btnSwitch.state = .on
                                        return;
                                    }
                                }
                            }
                            
                            if uIVcObj != nil{
                                if settingsContainerVcObj?.containerView.subviews.contains(uIVcObj!.view) ?? false{
                                    if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
                                        self.view.removeFromSuperview()
                                        uIVcObj?.showDockIconItemVcObj?.btnSwitch.state = .off
                                        return;
                                    }
                                }
                            }
                        }
                        
                        // if selectJsonVcObj != nil{
                        //                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                        //if tabview.selectedTabViewItemIndex == preferencesEditHabitsIndex{
                        self.view.removeFromSuperview()
                        
                        leftMenuVcObj?.showHelpAndSupportView()
                        return;
                                //}
        //                    }
                       // }

                        
                    }else{
                        self.view.removeFromSuperview()
                        if currentState != ._SHUTOFFMAC_ && currentState != ._FOCUS_SUMMARY_{
                            getHabitsVcObject().abortCancel()
                        }
                        return;
                    }
                    
                }
            }
        }
//        if preferencesWindowControllerObj != nil{ // ask password for password tab when PasswordRequireInChangeSettings is false
//            if self.view.window == preferencesWindowControllerObj?.window{
//                if passwordVcObj != nil{
//                    if settingsContainerVcObj?.containerView.subviews.contains(passwordVcObj!.view) ?? false{
//                        if !SettingsManagerObject.isPasswordRequireInChangeSettings{
//                            self.view.removeFromSuperview()
//                            passwordVcObj?.btnBackClicked(self)
//                            return;
//                        }
//                    }
//                }
//                
//                if selectJsonVcObj != nil{
//                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                        //if tabview.selectedTabViewItemIndex == preferencesEditHabitsIndex{
//                        self.view.removeFromSuperview()
//                        tabview.selectedTabViewItemIndex = 0
//                        return;
//                        //}
//                    }
//                }
//                
//                if frictionVcObj != nil{
//                    if settingsContainerVcObj?.containerView.subviews.contains(frictionVcObj!.view) ?? false{
//                        if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
//                            self.view.removeFromSuperview()
//                            frictionVcObj?.reloadAppAfterForceQuitItemVcObj?.btnSwitch.state = .on
//                            return;
//                        }
//                    }
//                }
//                
//                if uIVcObj != nil{
//                    if settingsContainerVcObj?.containerView.subviews.contains(uIVcObj!.view) ?? false{
//                        if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
//                            self.view.removeFromSuperview()
//                            uIVcObj?.showDockIconItemVcObj?.btnSwitch.state = .off
//                            return;
//                        }
//                    }
//                }
//            }
//        }
        
    
        if quittingWcObj != nil{//postpone cancel from password box
            if self.view.window == quittingWcObj?.window{
                if quittingWcObj?.contentViewController == askQuitVcObj{
                    self.view.removeFromSuperview()
                    return;
                }
            }
        }
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                if self.presentingViewController == popupAppointmentTimeVcObj{
                    self.dismiss(self)
                    return;
                }
            }
        }
        self.view.window?.close()
        self.view.removeFromSuperview()
        
    }
  
   
    @IBAction func btnResetPasswordClicked(_ sender: Any) {
        
        var alertTitle = "Reset Password"
        var alertSubTitle = "Your current password will be removed after 24 hours. You can then set a new password. Proceed?"
        
        if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
            if let title = enterPasswordViewInfo.value(forKey: "alertConfirmResetPasswordTitle") as? String{
                alertTitle = title
            }
            if let title = enterPasswordViewInfo.value(forKey: "alertConfirmResetPasswordSubTitle") as? String{
                alertSubTitle = title
            }
        }
        
        let alertReset: NSAlert = NSAlert()

        alertReset.setSharingType()
        alertReset.messageText = alertTitle
        alertReset.informativeText = alertSubTitle
        alertReset.alertStyle = NSAlert.Style.warning
        alertReset.addButton(withTitle: buttonOkText)
        alertReset.addButton(withTitle: buttonCancelText)
        
        
        alertReset.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")

                addLog(text: "[user-action] Enter password view reset clicked")
                if self.timerCheckClearPasswordTime != nil{
                    self.timerCheckClearPasswordTime?.invalidate()
                    self.timerCheckClearPasswordTime = nil
                }
                let Hours:TimeInterval = 24 * 60 * 60
                let date = Date().addingTimeInterval(Hours)//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
                UserDefaults.standard.set(date, forKey: kUserdefaults24HoursClearPasswordTime)
                addLog(text: "password will be clear after 24 hours - \(getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss"))")
                self.timerCheckClearPasswordTime = Timer.scheduledTimer(timeInterval: Hours, target: self, selector: #selector(self.clearPassword), userInfo: nil, repeats: false)
                self.btnResetPassword.setDisable(title: self.buttonResetPasswordText)
                
                var alertTitle = "Password reset in progress"
                var alertSubTitle = "Please set a new password after 24 hours."
                
                if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                    if let title = enterPasswordViewInfo.value(forKey: "alertPasswordResetDoneTitle") as? String{
                        alertTitle = title
                    }
                    if let title = enterPasswordViewInfo.value(forKey: "alertPasswordResetDoneSubTitle") as? String{
                        alertSubTitle = title
                    }
                }
                
                
                let alert: NSAlert = NSAlert()
                alert.setSharingType()
                alert.messageText = alertTitle
                alert.informativeText = alertSubTitle
                alert.alertStyle = NSAlert.Style.warning
                alert.addButton(withTitle: buttonOkText)
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        print("okclicked")
                        // self.txtFieldEmail.stringValue = ""
                        if isMainWindowLoaded{
                            if mainWindowControllerObj?.window!.isVisible ?? false{//it means isi per aaya hoga
                                self.view.removeFromSuperview()
                                if currentState != ._SHUTOFFMAC_{
                                    getHabitsVcObject().abortCancel()
                                }
                                return;
                            }
                        }
                        self.view.window?.close()
                        self.view.removeFromSuperview()
                    }
                })
                
            }
        })
    }
    var timerCheckClearPasswordTime:Timer?
    @objc func clearPassword(){
        UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
        SettingsManagerObject.appPassword.clear()
        addLog(text: "password is cleard after 24 hours")
    }
    
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        if textField == textFieldPassword || textField == textFieldRandomString{
            lblError.isHidden = true
            lblError.stringValue = ""
        }
    }
    func alertforvalidation(question: String, text: String) {
        let alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonOkText)

        
        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                // self.txtFieldEmail.stringValue = ""
            }
        })
        
    }
}

extension enterPasswordVc:NSTabViewDelegate{
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        print("tab view selection change")
        if tabViewItem == tabViewItemPassword{
            lblTitle.stringValue = "Please enter the password to continue"
            textFieldPassword.placeholderString = "Password"
            lblRandomString.isHidden = true
            textFieldPassword.isHidden = false
            textFieldRandomString.isHidden = true
            textFieldPassword.stringValue = ""
            if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                lblTitle.stringValue = enterPasswordViewInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
                textFieldPassword.placeholderString = enterPasswordViewInfo.value(forKey: "passwordPlaceholderText") as? String ?? textFieldPassword.placeholderString
            }
            showPasswordView()
            customViewAccountabilityBuddy.isHidden = true
            customViewAccountabilityBuddy.subviews.forEach { $0.removeFromSuperview() }
        }else if tabViewItem == tabViewItemEnterCharacters{
            textFieldPassword.isHidden = true
            textFieldRandomString.isHidden = false
            textFieldRandomString.stringValue = ""
            var title = "To unlock your machine without a password, enter these characters. You said you wanted it to be hard to use your computer impulsively 😅"
            if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                title = enterPasswordViewInfo.value(forKey: "titleEnterCharacters") as? String ?? title
            }
            let randomString = randomString(length: 100)
            print(randomString)
            lblRandomString.stringValue = randomString
            randomCharacters = lblRandomString.stringValue
            lblRandomString.isHidden = false
            
            lblTitle.stringValue = title
            showPasswordView()
            customViewAccountabilityBuddy.isHidden = true
            customViewAccountabilityBuddy.subviews.forEach { $0.removeFromSuperview() }
        }else if tabViewItem == tabViewItemAccountabilityBuddy{
            hidePasswordView()
            customViewAccountabilityBuddy.isHidden = false
            if !getAccountabilityBuddyVcObject().isViewLoaded{
                getAccountabilityBuddyVcObject().loadView()
            }
            getAccountabilityBuddyVcObject().enterPasswordVcObj = self
            customViewAccountabilityBuddy.addSubview(getAccountabilityBuddyVcObject().view)
            customViewAccountabilityBuddy.addConstraints(subView: getAccountabilityBuddyVcObject().view)
            
        }
    }

    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if tabViewItem == tabViewItemPassword{
            if !SettingsManagerObject.isAppPasswordSet{
                return false
            }
        }
        
        return true
    }
}
