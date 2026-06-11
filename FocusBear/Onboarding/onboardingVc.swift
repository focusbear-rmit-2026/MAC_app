//
//  onboardingVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 26/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingVc: NSViewController {

    @IBOutlet weak var btnBack: Button!
    @IBOutlet weak var containerView: NSView!

    enum ONBOARDINGSTATE: Int {
        
        case _NOTHING_ = 111
        
        // Welcome Flow
        case _WELCOME_
        case _WELCOME_ADHD_
        case _WELCOME_LETS_DO_IT_
        
        // Account Setup
        case _SET_UP_ACCOUNT_
        case _PRIVACY_POLICY_
        case _CREATE_ACCOUNT_
        case _LOGIN_
        
        // Initial Setup
        case _HOLD_ON_
        case _SET_UP_HABITS_
        case _START_SET_UP_HABITS_
        case _INSTALL_HABIT_PACKS_
        
        // Blocking Setup
        case _SET_DISTRACTION_BLOCKING_
        case _ENABLE_AI_BLOCKING_
        case _ASK_SET_DISTRACTIONS_
        
        // User Info
        case _ASK_OCCUPATION_
        
        // Blocking Configuration
        case _ALLOWED_URLS_
        case _BLOCKED_URLS_
        case _BLOCKED_APPS_
        
        // Schedule
        case _ASK_CREATE_BLOCKING_SCHEDULE_
        case _CREATE_BLOCKING_SCHEDULE_
        
        // Permissions
        case _ASK_PERMISSIONS_
        case _SYSTEM_EVENT_PERMISSION_
        case _ACCESSIBILITY_PERMISSION_
        case _BROWSERS_PERMISSION_
        
        // Completion
        case _ALL_SET_
    }
    
    var currentOnboardingState:ONBOARDINGSTATE = ._NOTHING_
    var onboardingStack: [ONBOARDINGSTATE] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        currentOnboardingState = ._NOTHING_
        let orangeColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        btnBack.borderColor = orangeColor.withAlphaComponent(0.5).cgColor
        btnBack.buttonColor = orangeColor.withAlphaComponent(0.1).cgColor
    }
    
    func onboardingFinished(){
        mainViewControllerObj?.onboardingFinishedUnlockMachine()
        currentOnboardingState = ._NOTHING_
    }
    
    func removeSubViews(){
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
    }

    
    func blockingScheduleSkipped(){
        if SettingsManagerObject.arrBlockedUrls.count == 0 && SettingsManagerObject.arrBlockedApps.count == 0{
            navigate(to: ._ALL_SET_)
        }else{
            navigate(to: ._ASK_PERMISSIONS_)
            getAskPermissionsVcObj().blockingScheduleSkipped()
        }
        
    }
    
    func navigateToAllowedUrlsVc(){
        navigate(to: ._ALLOWED_URLS_)
        getOnboardingAllowedUrlsVcObject().resetUrlsList()
    }
    
    func navigateToInstallHabitVc(suggestHabits:Bool){
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        mainViewControllerObj?.showLoaderView()
        getInstallHabitPacksVcObj().loadwebViewWithCompletion(suggestHabits: suggestHabits, completionHandler: {
            self.navigate(to: ._INSTALL_HABIT_PACKS_)
            mainViewControllerObj?.hideLoaderView()
        })
    }
    
    func navigate(to state: ONBOARDINGSTATE) {
        
        // Push current state into stack before changing
        if currentOnboardingState != ._NOTHING_ {
            onboardingStack.append(currentOnboardingState)
        }
        
        currentOnboardingState = state
        
        removeSubViews()
        
        switch state {
            
        case ._NOTHING_:
            break
            
        case ._WELCOME_:
            addLog(text: "Showing Welcome view.")
            containerView.addSubview(getWelcomeVcObject().view)
            btnBack.isHidden = true
            
        case ._WELCOME_ADHD_:
            addLog(text: "Showing Welcome ADHD view.")
            containerView.addSubview(getWelcomeAdhdVcObject().view)
            btnBack.isHidden = false
            
        case ._WELCOME_LETS_DO_IT_:
            addLog(text: "Showing Welcome LetsDoIt view.")
            containerView.addSubview(getWelcomeLetsDoItVcObject().view)
            btnBack.isHidden = false
            
        case ._SET_UP_ACCOUNT_:
            addLog(text: "Showing SetUp Account view.")
            containerView.addSubview(getSetUpAccountVcObject().view)
            btnBack.isHidden = false
            
        case ._PRIVACY_POLICY_:
            addLog(text: "Showing Privacy Tip view.")
            containerView.addSubview(getOnboardingPrivacyTipVcObject().view)
            btnBack.isHidden = false
            
        case ._CREATE_ACCOUNT_:
            addLog(text: "Showing Ask LogIn view.")
            containerView.addSubview(getAskLogInVcObject().view)
            btnBack.isHidden = false
            
        case ._LOGIN_:
            addLog(text: "Showing LogIn view.")
            containerView.addSubview(getCustomLoginVcObject().view)
            btnBack.isHidden = false
            
        case ._HOLD_ON_:
            addLog(text: "Showing HoldOn view.")
            containerView.addSubview(getHoldOnVcObject().view)
            btnBack.isHidden = false
            
        case ._SET_UP_HABITS_:
            addLog(text: "Showing setup habits view.")
            containerView.addSubview(getSetUpHabitsVcObject().view)
            btnBack.isHidden = false
            
        case ._START_SET_UP_HABITS_:
            addLog(text: "Showing start setup habits view.")
            containerView.addSubview(getStartSetUpHabitsVcObject().view)
            btnBack.isHidden = false
            
        case ._INSTALL_HABIT_PACKS_:
            addLog(text: "Showing install Habit Packs view.")
            containerView.addSubview(getInstallHabitPacksVcObj().view)
            btnBack.isHidden = true
            
        case ._SET_DISTRACTION_BLOCKING_:
            addLog(text: "Showing set scheduled distraction blocking view.")
            containerView.addSubview(getSetScheduledDistractionBlockingVcObj().view)
            btnBack.isHidden = false
            
        case ._ENABLE_AI_BLOCKING_:
            addLog(text: "Showing Enable AI Blocking view.")
            containerView.addSubview(getEnableAIBlockingVcObject().view)
            btnBack.isHidden = false
            
        case ._ASK_SET_DISTRACTIONS_:
            addLog(text: "Showing ask set distractions view.")
            containerView.addSubview(getAskSetDistractionsVcObject().view)
            btnBack.isHidden = false
            
        case ._ASK_OCCUPATION_:
            addLog(text: "Showing ask occupation view.")
            containerView.addSubview(getAskOccupationVcObject().view)
            btnBack.isHidden = false
        case ._ALLOWED_URLS_:
            addLog(text: "Showing onboarding allowed urls view.")
            containerView.addSubview(getOnboardingAllowedUrlsVcObject().view)
            btnBack.isHidden = false
        case ._BLOCKED_URLS_:
            addLog(text: "Showing onboarding blocked urls view.")
            containerView.addSubview(getOnboardingBlockedUrlsVcObject().view)
            btnBack.isHidden = false
        case ._BLOCKED_APPS_:
            addLog(text: "Showing onboarding blocked apps view.")
            containerView.addSubview(getOnboardingBlockedAppsVcObject().view)
            btnBack.isHidden = false
        case ._ASK_CREATE_BLOCKING_SCHEDULE_:
            addLog(text: "Showing ask create blocking schedule view.")
            containerView.addSubview(getConfirmBlockingScheduleCreationVcObj().view)
            btnBack.isHidden = false
        case ._CREATE_BLOCKING_SCHEDULE_:
            addLog(text: "Showing create blocking schedule view.")
            containerView.addSubview(getCreateFirstBlockingScheduleVcObj().view)
            btnBack.isHidden = false
        case ._ASK_PERMISSIONS_:
            addLog(text: "Showing ask permissions view.")
            containerView.addSubview(getAskPermissionsVcObj().view)
            btnBack.isHidden = false
        case ._SYSTEM_EVENT_PERMISSION_:
            addLog(text: "Showing system events permission view.")
            containerView.addSubview(getSystemEventsPermissionVcObject().view)
            btnBack.isHidden = false
        case ._ACCESSIBILITY_PERMISSION_:
            addLog(text: "Showing accessibility permission view.")
            containerView.addSubview(getAccessibilityPermissionVcObject().view)
            btnBack.isHidden = false
        case ._BROWSERS_PERMISSION_:
            addLog(text: "Showing browsers permission view.")
            containerView.addSubview(getOnboardingControllingBrowserVcObject().view)
            btnBack.isHidden = false
        case ._ALL_SET_:
            addLog(text: "Showing All set view.")
            containerView.addSubview(getAllSetVcObject().view)
            btnBack.isHidden = false
        }
        
        // Add constraints once
        if let subview = containerView.subviews.last {
            containerView.addConstraints(subView: subview)
        }
        
        if onboardingStack.count < 1 || currentState != ._ONBOARDING_{// Login screens are part of onboarding. Hide the back button when normal login is shown.
            btnBack.isHidden = true
        }
    }
    
    
    @IBAction func btnBackClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingVc:- btnBackClicked.")
        if currentOnboardingState == ._HOLD_ON_{// v 3.31.473
            
            var alertTitleLogout = "Do you want to log out and start again?"
            var buttonLogout = "Yes - logout"
            var buttonNo = "Oops no"
            
            if let holdOnVcInfo = configjson["holdOnVcInfo"] as? [String: Any] {
                alertTitleLogout = holdOnVcInfo["alertTitleLogout"] as? String ?? alertTitleLogout
                buttonLogout = holdOnVcInfo["buttonLogout"] as? String ?? buttonLogout
                buttonNo = holdOnVcInfo["buttonNo"] as? String ?? buttonNo
            }
            
            showCustomAlert(title: alertTitleLogout, body: nil, buttonOkText: buttonLogout, buttonCancelText: buttonNo, checkBoxText: nil, autoClose: false, buttonLinkUrl:nil, buttonLinkText: nil, completionHandler: {isOkClicked in
                print(isOkClicked)
                if isOkClicked{
                    addLog(text: "Logout:- back to create account view")
                    // logout
                    appdelegate!.user = nil
                    let _ = appdelegate!.credentialsManager.clear()
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsIsUserLoggedIn)
                    UserDefaults.standard.removeObject(forKey: kUserDefaultsLastUserLoginWithGoogle)
                    appdelegate!.needToCheckEmailVerification = false
                    appdelegate!.credential = nil
                    

                    appdelegate!.sharedDefaults?.removeObject(forKey: kUserdefaultsSharedUserId)
                    appdelegate!.sharedDefaults?.removeObject(forKey: kUserdefaultsSharedAccessToken)
                    appdelegate!.sharedDefaults?.removeObject(forKey: kUserdefaultsSharedAppVersion)
                    appdelegate!.sharedDefaults?.synchronize()
                    kUserdefaultsVideoShown = "kUserdefaultsVideoShown"
                    kUserDefaultsBlockingScheduleAddedFirstTime = "kBlockingScheduleAddedFirstTime"

                    self.goBack()// goes to login
                    if self.currentOnboardingState != ._CREATE_ACCOUNT_{
                        self.goBack()// goes to create account
                    }
                }
            })
            return;
        }else if currentOnboardingState == ._SET_DISTRACTION_BLOCKING_{// v 3.31.473
            //If they set up habits, take them to edit-habits
            self.goBack()
            
            //If they skipped/no habits, then take them back to routine-suggestions-revamped
            if getInstallHabitPacksVcObj().hasSkippedHabits && currentOnboardingState == ._INSTALL_HABIT_PACKS_{
                self.goBack()
            }
            
            if currentOnboardingState == ._INSTALL_HABIT_PACKS_{
                getInstallHabitPacksVcObj().reloadWebView()
            }
            return;
        }
        goBack()
    }
    
    func goBack(){
        guard let previousState = onboardingStack.popLast() else { return }
        currentOnboardingState = ._NOTHING_ // prevent re-push
        navigate(to: previousState)
    }
}
