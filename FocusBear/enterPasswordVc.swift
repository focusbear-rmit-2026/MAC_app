//
//  enterPasswordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class enterPasswordVc: NSViewController, NSTextFieldDelegate {
   
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
    @IBOutlet weak var lblError: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var textFieldPassword: NSSecureTextField!
    @IBOutlet weak var btnResetPassword: underLineButton!
    @IBOutlet weak var btnOk: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    
    var isCurrentViewInMainWindow = false
    var buttonResetPasswordText = "Reset Password"
    var randomCharacters = ""
    var parentVc:NSViewController?
    var isShowingForRelaxFocusMode = false
    var isShowingForDeactivatingApp = false
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
        }
        btnResetPassword.title = buttonResetPasswordText
        
        btnOk.title = buttonOkText//"OK"
        btnCancel.title = buttonCancelText//"Cancel"
        textFieldPassword.delegate = self
        btnResetPassword.isHidden = true
        tabView.delegate = self
        
        
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
        randomCharacters = ""
        tabView.selectTabViewItem(tabViewItemPassword)
        isCurrentViewInMainWindow = false
        lblError.isHidden = true
        lblError.stringValue = ""
        textFieldPassword.stringValue = ""
        //btnResetPassword.isHidden = false
        
        if UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) == nil{//if reset is in progress then disable reset button
            btnResetPassword.setEnable(title: buttonResetPasswordText)
        }else{
            btnResetPassword.setDisable(title: buttonResetPasswordText)
        }
        
        if isMainWindowLoaded{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                //btnResetPassword.isHidden = true
                isCurrentViewInMainWindow = true
                return;//
            }
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
            
            if let passwordBase64 = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) as? String{
                if let password = passwordBase64.fromBase64(){
                    if textFieldPassword.stringValue == password{
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
    }
    
    func authenticated(){
        if parentVc != nil{
//            if parentVc == startingFocusModeVcObj{
//                self.dismiss(self)
//                let totalMinutes = (startingFocusModeVcObj!.textFieldHourValue.integerValue * 60) + startingFocusModeVcObj!.textFieldMinutesValue.integerValue
//                if currentState == ._POSTPON_MORNING_HABIT_{
//                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
//                }else if currentState == ._POSTPON_EVENING_HABIT_{
//                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
//                }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
//                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
//                }
//                startingFocusModeVcObj!.checkTotalMinutesAndStart()
//                return;
//            }else
            
            if parentVc == pomodoroVcObj{
                self.dismiss(self)
                let totalMinutes = pomodoroVcObj!.textFieldWorkDuration.integerValue
                if currentState == ._POSTPON_MORNING_HABIT_ && !isShowingForRelaxFocusMode{
                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                    pomodoroVcObj!.checkStateAndStartPomodoroMode()
                }else if currentState == ._POSTPON_EVENING_HABIT_ && !isShowingForRelaxFocusMode{
                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                    pomodoroVcObj!.checkStateAndStartPomodoroMode()
                }else if currentState == ._POSTPON_FOCUS_SUMMARY_ && !isShowingForRelaxFocusMode{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                    pomodoroVcObj!.checkStateAndStartPomodoroMode()
                }else if isShowingForRelaxFocusMode{
                    pomodoroVcObj!.pomodoroModeStarted()
                    pomodoroVcObj?.view.window?.close()
                }
                isShowingForRelaxFocusMode = false
                return;
            }else if parentVc == focusEndWarningVcObj{
                self.dismiss(self)
                let totalMinutes = Int(focusEndWarningVcObj?.popUpBtn.title ?? "1") ?? 0
                if currentState == ._POSTPON_MORNING_HABIT_{
                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if currentState == ._POSTPON_EVENING_HABIT_{
                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                }
                focusEndWarningVcObj!.extendFocusMode()
                return;
            }else if parentVc == addTaskVcObj{
                self.dismiss(self)
                let totalMinutes = Int(addTaskVcObj?.popUpBtnSelectMinutes.title ?? "1") ?? 0
                if currentState == ._POSTPON_MORNING_HABIT_{
                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if currentState == ._POSTPON_EVENING_HABIT_{
                    getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                }
                addTaskVcObj?.extendFocusMode()
                return;
            }else if parentVc == simplePomodoroVcObj{
                self.dismiss(self)
                let totalMinutes = simplePomodoroVcObj!.textFieldWorkDuration.integerValue
                getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                simplePomodoroVcObj!.pomodoroModeStarted()
                simplePomodoroVcObj?.view.window?.close()
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
                        getHabitsVcObject().showAskPostponeView()
                        return;
                    }
                    
                    
                }else if lastCurrentState == ._EVENING_HABIT_{
                    var postponeTime = 0
                    if askPostponeVcObj != nil{
                        if askPostponeVcObj!.popUpButtonSelectMinutes != nil{
                            postponeTime = Int(askPostponeVcObj!.popUpButtonSelectMinutes.title) ?? 15
                        }
                    }
                    if activityPostponeCount == 0 && postponeTime > 15{
                        activityPostponeCount += 1
                        self.view.removeFromSuperview()
                        getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
                        return;
                    }else{
                        self.view.removeFromSuperview()
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
                firstViewControllerObj?.showEditHabitsView()
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
                    
                    if (leftMenuVcObj?.boxBlocks.isSelected ?? false) || (leftMenuVcObj?.boxFocusModeSettings.isSelected ?? false) || (leftMenuVcObj?.boxSettings.isSelected ?? false) || (leftMenuVcObj?.boxEditHabits.isSelected ?? false){
                        
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
        
        
//        if preferencesWindowControllerObj != nil{
//            if self.view.window == preferencesWindowControllerObj?.window{
//                if selectJsonVcObj != nil{
//                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                        if tabview.selectedTabViewItemIndex == preferencesEditHabitsIndex{
//                            self.view.removeFromSuperview()
//                            return;
//                        }
//                    }
//                }
//            }
//        }
        
        
        
        
        
        
        self.view.removeFromSuperview()
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "[user-action] Enter password view - cancel clicked")
        allApiObject.capturePosthog(event: "cancel-when-prompted-password", metadata: [:])
        if parentVc != nil{
//            if parentVc == startingFocusModeVcObj{
//                self.dismiss(self)
//                startingFocusModeVcObj!.checkTotalMinutesAndStart()
//                return;
//            }else
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
                        easyPostponeWcObj?.window?.close()
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
                    
                    
                    
                    if (leftMenuVcObj?.boxBlocks.isSelected ?? false) || (leftMenuVcObj?.boxFocusModeSettings.isSelected ?? false) || (leftMenuVcObj?.boxSettings.isSelected ?? false) || (leftMenuVcObj?.boxEditHabits.isSelected ?? false){
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
        UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
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
            
        }
    }

    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        return true
    }
}
