//
//  askPostponeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

class askPostponeVc: NSViewController {

    // #1590: for the mid-break "are you sure" confirmation, replace the passive
    // countdown with the same press-and-hold-to-postpone friction used on the
    // pre-break warning popup (escalating hold time by activityPostponeCount).
    private var holdHostingView: NSView?
    private var eveningInstructionHostingView: NSView?
    private var eveningHoldGuide: NSLayoutGuide?

    /// Evening "hold-to-set" postpone: minutes resolved from the last press-and-hold.
    /// Readers on the evening postpone path (this VC and enterPasswordVc) use this
    /// instead of `popUpButtonSelectMinutes.title`, which the evening flow hides.
    var resolvedEveningPostponeMinutes: Int?

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
            // abortCancel() re-shows the Postpone (abort) button for its covered states (micro-break /
            // morning / evening / shutoff / custom), but has NO branch for a special activity, so cancelling
            // postpone there left the button hidden (lost). Restore it here for the uncovered states —
            // except focus summary, where abortCancel() deliberately hides it.
            if lastCurrentState != ._FOCUS_SUMMARY_ {
                getHabitsVcObject().showCloseButtons()
            }
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    func resetView(){
        addLog(text: "Ask postpone view - resetView")
        hideHoldToPostpone()
        resolvedEveningPostponeMinutes = nil
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
            
            btnPostpone.isSecondaryButton = false
            btnAbortBreak.isSecondaryButton = true
        }else if currentState == ._MICRO_BREAK_{
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
       
        btnPostpone.isSecondaryButton = false
        btnAbortBreak.isSecondaryButton = true
        
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

        // #1590: hold-to-postpone instead of the 15s countdown.
        lblTimer.isHidden = true
        // Same escalating hold as the pre-break warning (5s → 10s → 15s).
        showHoldToPostpone(seconds: Double(min(15, 5 * (breakPostponeHoldCount + 1))),
                           title: "Postpone",
                           onComplete: { [weak self] in self?.performMicroBreakHoldPostpone() })
    }

    /// Shows a press-and-hold "Postpone" control over the confirmation. The hold itself
    /// is the friction (escalating duration); `onComplete` runs once the hold finishes.
    private func showHoldToPostpone(seconds: Double, title: String, onComplete: @escaping () -> Void) {
        hideHoldToPostpone()
        let accent = Color(red: 232 / 255, green: 136 / 255, blue: 0 / 255)
        let control = HoldToPostponeButton(seconds: seconds, title: title, accent: accent,
                                           onComplete: onComplete)
        let hv = NSHostingView(rootView: control)
        hv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hv)
        NSLayoutConstraint.activate([
            hv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hv.centerYAnchor.constraint(equalTo: lblTimer.centerYAnchor),
            hv.widthAnchor.constraint(equalToConstant: 240),
            hv.heightAnchor.constraint(equalToConstant: 34),
        ])
        holdHostingView = hv
    }

    private func hideHoldToPostpone() {
        holdHostingView?.removeFromSuperview()
        holdHostingView = nil
        eveningInstructionHostingView?.removeFromSuperview()
        eveningInstructionHostingView = nil
        if let g = eveningHoldGuide { view.removeLayoutGuide(g); eveningHoldGuide = nil }
    }

    private func performMicroBreakHoldPostpone() {
        addLog(text: "[user-action] Ask postpone view - hold-to-postpone completed")
        let postponeTime = Int(popUpButtonSelectMinutes.title) ?? breakAfterMinutes
        hideHoldToPostpone()
        self.timer?.invalidate()
        self.timer = nil
        activityPostponeCount += 1
        breakPostponeHoldCount += 1   // escalate the hold for the next break
        self.view.removeFromSuperview()
        getHabitsVcObject().postponeBreakActivitiesFor(minutes: postponeTime, secondsToPostpone: nil, isFromBreakWarningWindow: false)
    }
    var isShowingAskOfficeModeView = false
    func showAskOfficeModeView(){
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        var currentActicityTitle = ""
        if currentAction == ._INPROGRESS_{
            currentActicityTitle = timerViewcontrollerObj?.currentActicityTitle ?? ""
        }else if currentAction == ._END_{
            currentActicityTitle = activityCompletionVcObj?.activityName ?? ""
        }else if currentAction == ._START_{
            currentActicityTitle = activityCompletionVcObj?.activityName ?? ""
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
        btnPostpone.isSecondaryButton = true
        btnAbortBreak.isSecondaryButton = false

//        }
        
    }
    func showHabitTimerView(){
        lblTitle.stringValue = "You've postponed your habits a few times. Are you sure you want to postpone again?"
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        btnAbortBreak.isHidden = true
        btnPostpone.isHidden = true
        btnOkIWillDoBreak.isHidden = true
        
        // #1590: replace the escalating countdown with a press-and-hold gate (5→10→15s,
        // capped). Completing the hold proceeds to the postpone options, preserving the
        // existing password / cut-off logic in showHabitPostponeView/btnPostponeClicked.
        lblTimer.isHidden = true
        showHoldToPostpone(seconds: Double(min(15, max(5, 5 * activityPostponeCount))),
                           title: "Postpone habit",
                           onComplete: { [weak self] in
                               self?.hideHoldToPostpone()
                               self?.showHabitPostponeView()
                           })
        btnOkIWillDoBreak.isHidden = false
        btnOkIWillDoBreak.title = "I changed my mind - I'll do my habits"
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponedLastHabitText") as? String ?? lblTitle.stringValue
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonDoHabitText") as? String ?? btnOkIWillDoBreak.title
        }
        
    }
    
    func showHabitPostponeView(){
        // Evening postpone uses a press-and-hold "hold-to-set" control instead of the
        // minutes dropdown — deliberate friction so a long postpone can't be picked by
        // accident. Morning/other routines keep the existing dropdown.
        if currentState == ._EVENING_HABIT_{
            showEveningHoldToSetPostponeView()
            return
        }
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
        
        btnPostpone.isSecondaryButton = false
        btnAbortBreak.isSecondaryButton = true
        btnOkIWillDoBreak.isHidden = true
        btnPostpone.isHidden = false
        btnAbortBreak.isHidden = false
    }

    /// Evening-only postpone screen: the minutes dropdown + "Postpone Habit" button are
    /// replaced by a press-and-hold control that accumulates the postpone duration while
    /// held (see `HoldToSetPostponeControl`). "Completely Skip" (btnAbortBreak) stays.
    private func showEveningHoldToSetPostponeView(){
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        btnPostpone.isHidden = true
        btnOkIWillDoBreak.isHidden = true
        lblTimer.isHidden = true

        let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary
        lblTitle.stringValue = activityPostponeInfo?.value(forKey: "postponeHabitsText") as? String ?? "If you have something urgent, you can postpone Habits for a few minutes." // i18n-ignore
        btnAbortBreak.title = activityPostponeInfo?.value(forKey: "buttonCompletelySkipText") as? String ?? "Completely Skip" // i18n-ignore
        btnAbortBreak.isSecondaryButton = true
        btnAbortBreak.isHidden = false

        showEveningHoldToSetControl()
    }

    /// Hosts the SwiftUI hold-to-set control over the dropdown's position. On release it
    /// resolves the held minutes, records them for the password-path reader, and runs the
    /// same evening postpone decision as the old "Postpone Habit" button.
    private func showEveningHoldToSetControl(){
        hideHoldToPostpone()
        var instruction = "Press and hold to choose how long to postpone — the longer you hold, the longer the postpone. Release to confirm."
        var liveTemplate = "Postpone for <MIN> min…"
        var idleTitle = "Hold to postpone"
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            instruction = activityPostponeInfo.value(forKey: "eveningHoldInstruction") as? String ?? instruction
            liveTemplate = activityPostponeInfo.value(forKey: "eveningHoldLiveText") as? String ?? liveTemplate
            idleTitle = activityPostponeInfo.value(forKey: "eveningHoldIdleText") as? String ?? idleTitle
        }
        let accent = Color(red: 232 / 255, green: 136 / 255, blue: 0 / 255)

        // Instruction is its own view (intrinsic height, NOT greedy) pinned a comfortable gap below
        // the title — so it can never pull the title's bottom up / compress the title away.
        let instructionText = Text(instruction)
            .font(postponeMediumFont(12))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        let instrHV = NSHostingView(rootView: instructionText)
        instrHV.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instrHV)
        eveningInstructionHostingView = instrHV

        let control = HoldToSetPostponeControl(accent: accent,
                                               instruction: instruction,
                                               liveTemplate: liveTemplate,
                                               idleTitle: idleTitle,
                                               onCommit: { [weak self] minutes in
                                                   guard let self = self else { return }
                                                   self.resolvedEveningPostponeMinutes = minutes
                                                   self.hideHoldToPostpone()
                                                   self.commitEveningPostpone(minutes: minutes)
                                               })
        let hv = NSHostingView(rootView: control)
        hv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hv)
        holdHostingView = hv

        // A guide spanning the gap between the instruction's bottom and "Completely Skip"; the hold
        // button is centred in it, so it sits midway between the instruction and Skip regardless of
        // how many lines the instruction wraps to.
        let guide = NSLayoutGuide()
        view.addLayoutGuide(guide)
        eveningHoldGuide = guide

        NSLayoutConstraint.activate([
            instrHV.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instrHV.widthAnchor.constraint(equalToConstant: 360),
            instrHV.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 30),

            guide.topAnchor.constraint(equalTo: instrHV.bottomAnchor),
            guide.bottomAnchor.constraint(equalTo: btnAbortBreak.topAnchor),

            hv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hv.widthAnchor.constraint(equalToConstant: 360),
            hv.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
        ])
    }

    /// Evening postpone decision (password gating vs. postpone), shared by the hold-to-set
    /// control and the legacy `btnPostponeClicked` path. `shouldAskPassword`'s 2-minute
    /// window prevents a double prompt if a password was just entered.
    private func commitEveningPostpone(minutes postponeTime: Int){
        // After the cutoff time the "require password to postpone evening after cutoff" rule
        // applies for ANY postpone length. Before cutoff, only the first >15-minute postpone
        // is gated (#441).
        var requirePassword = false
        if shouldAskPassword(forPostpone: true){
            if isCutOffTimeGoing(){// changed in 2.27.422 : isHighPrioritySequenceGoing -> isCutOffTimeGoing()
                requirePassword = SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff
            }else if activityPostponeCount == 0 && postponeTime > 15{
                requirePassword = SettingsManagerObject.isPasswordRequireInPostponeEvening
            }
        }
        if requirePassword{
            self.view.removeFromSuperview()
            getHabitsVcObject().showPasswordView()
            enterPasswordVcObj?.parentVc = self
        }else{
            activityPostponeCount += 1
            self.view.removeFromSuperview()
            getHabitsVcObject().postponeEveningHabitFor(minutes: postponeTime, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true)
        }
    }


    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "[user-action] Ask postpone view - button Postpone Clicked")
        let postponeTime = Int(popUpButtonSelectMinutes.title) ?? 15
        if currentState == ._MORNING_HABIT_{
            if activityPostponeCount == 0 && postponeTime > 15{//when user clicks Please spare me for the first time, if the user selects to postpones for longer than 15 then the password will be asked.//#441
                
                if shouldAskPassword(forPostpone: true) && SettingsManagerObject.isPasswordRequireInPostponeMorning{
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
            // Evening now commits via the hold-to-set control (see commitEveningPostpone);
            // fall back to resolved/dropdown minutes if the button is ever reached directly.
            commitEveningPostpone(minutes: resolvedEveningPostponeMinutes ?? postponeTime)
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
            
            if shouldAskPassword(forPostpone: true) && !SettingsManagerObject.isEasySkipEnabled{
                var shouldShowPasswordView = false
                if cutOffTime != nil{
                    if isCutOffTimeGoing(){
                        if SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff{
                            shouldShowPasswordView = true
                        }
                    }else{
                        if SettingsManagerObject.isPasswordRequireInPostponeEvening{
                            shouldShowPasswordView = true
                        }
                    }
                }else{
                    if SettingsManagerObject.isPasswordRequireInPostponeEvening{
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

/// Tuning for the evening "hold-to-set" postpone control. Holding accumulates minutes at
/// `minutesPerSecondHeld`; a quick tap yields `floorMinutes`, and holding is capped at
/// `capMinutes`. At 6 min/sec, reaching 90 min needs a ~15s hold and the 120-min cap ~20s.
private enum EveningPostponeHold {
    static let minutesPerSecondHeld: Double = 6
    static let floorMinutes = 5
    static let capMinutes = 120
    static let tickInterval: TimeInterval = 0.05
}

private func postponeMediumFont(_ size: CGFloat) -> Font { Font(getMediumFont(size: size)) }

/// Press-and-hold control for choosing the evening postpone duration. While pressed, the
/// duration accumulates at `EveningPostponeHold.minutesPerSecondHeld` and is shown live; a
/// progress fill tracks how close the hold is to the cap. Releasing commits the accumulated
/// value (floored/capped) via `onCommit`. This deliberate friction stops a long postpone
/// from being chosen with a single accidental click.
struct HoldToSetPostponeControl: View {
    let accent: Color
    let instruction: String
    let liveTemplate: String   // contains the "<MIN>" placeholder
    let idleTitle: String
    var onCommit: (Int) -> Void

    @SwiftUI.State private var minutesHeld: Double = 0
    @SwiftUI.State private var isPressing = false
    @SwiftUI.State private var accumulator: Timer?

    private var displayMinutes: Int {
        max(EveningPostponeHold.floorMinutes, min(EveningPostponeHold.capMinutes, Int(minutesHeld.rounded())))
    }

    private var progress: CGFloat {
        CGFloat(min(1, minutesHeld / Double(EveningPostponeHold.capMinutes)))
    }

    private var buttonLabel: String {
        guard isPressing else { return idleTitle }
        return liveTemplate.replacingOccurrences(of: "<MIN>", with: "\(displayMinutes)")
    }

    var body: some View {
        // Button only. The instruction line is a separate view positioned in
        // `showEveningHoldToSetControl`, so the button can be centred between the instruction and
        // "Completely Skip" without this view greedily filling height (which compressed the title).
        ZStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.12))
                    RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.35))
                        .frame(width: geo.size.width * progress)
                }
            }
            Text(buttonLabel)
                .font(postponeMediumFont(13))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressing { startHold() } }
                .onEnded { _ in endHold() }
        )
        .accessibility(label: Text(instruction))
    }

    private func startHold() {
        isPressing = true
        minutesHeld = 0
        accumulator?.invalidate()
        let tick = Timer(timeInterval: EveningPostponeHold.tickInterval, repeats: true) { _ in
            let next = minutesHeld + EveningPostponeHold.minutesPerSecondHeld * EveningPostponeHold.tickInterval
            minutesHeld = min(Double(EveningPostponeHold.capMinutes), next)
        }
        RunLoop.main.add(tick, forMode: .common)
        accumulator = tick
    }

    private func endHold() {
        accumulator?.invalidate()
        accumulator = nil
        guard isPressing else { return }
        isPressing = false
        let resolved = displayMinutes
        minutesHeld = 0
        onCommit(resolved)
    }
}
