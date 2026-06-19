//
//  WhySkipHabitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/12/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class whySkipHabitVc: NSViewController {

    @IBOutlet weak var btnSkipCompletely: underLineButton!
    @IBOutlet weak var btnCanNotDoIt: Button!
    @IBOutlet weak var btnAlreadyDidIt: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnSkipCompletely.title = "Skip micro break Completely"
        lblTitle.stringValue = "Why do you want to skip?"
        btnAlreadyDidIt.title = "I already did it"
        btnCanNotDoIt.title = "Can't do it today"
        
        if let whySkipHabitVcInfo = configjson.value(forKey: "whySkipHabitVcInfo") as? NSDictionary{
            lblTitle.stringValue = whySkipHabitVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnAlreadyDidIt.title = whySkipHabitVcInfo.value(forKey: "buttonAlreadyDidItText") as? String ?? btnAlreadyDidIt.title
            btnCanNotDoIt.title = whySkipHabitVcInfo.value(forKey: "buttonCanNotDoItText") as? String ?? btnCanNotDoIt.title
            btnSkipCompletely.title = whySkipHabitVcInfo.value(forKey: "buttonSkipBreaksCompletely") as? String ?? btnSkipCompletely.title
        }
        btnCanNotDoIt.isSecondaryButton = true
    }
    
    override func viewWillAppear() {
        if currentState == ._MICRO_BREAK_{
            btnSkipCompletely.isHidden = false
        }else{
            btnSkipCompletely.isHidden = true
        }
    }
    
    func skipActivityAlreadyDid(){
        if rememberNextHabitVcObj != nil{
            if activityCompletionVcObj!.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj!.view.removeFromSuperview()
                activityCompletionVcObj?.boxBg.isHidden = false
            }
        }
        if currentAction == ._VISUALIZE_{
            getHabitsVcObject().showThirdVc()
        }
        if currentAction == ._INPROGRESS_{
            getHabitsVcObject().showThirdVc()
        }
        
        if currentAction == ._START_{// break activity case
            getHabitsVcObject().showThirdVc()
        }
        
        if currentState == ._MICRO_BREAK_{
            activityCompletionVcObj?.activitySkippedAndDoneAlready()
        }else if currentState == ._MORNING_HABIT_{
            activityCompletionVcObj?.morningHabitSkippedAndDoneAlready()
        }else if currentState == ._EVENING_HABIT_{
            activityCompletionVcObj?.eveningHabitSkippedAndDoneAlready()
        }else if currentState == ._CUSTOM_ROUTINE_{
            activityCompletionVcObj?.customRoutineHabitSkippedAndDoneAlready()
        }
    }
    
    @IBAction func btnAlreadyDidItClicked(_ sender: Any) {
        addLog(text: "[user-action] whySkipHabitVc:- button AlreadyDidItClicked")
        self.view.removeFromSuperview()
        
        if currentState == ._MICRO_BREAK_{
            skipActivityAlreadyDid()
        }else{
            if shouldAskPassword(){
                if currentState == ._MORNING_HABIT_{
                    if SettingsManagerObject.isPasswordRequireInSkipMorning{
                        mainViewControllerObj?.showPasswordView()
                        enterPasswordVcObj?.parentVc = self
                    }else{
                        skipActivityAlreadyDid()
                    }
                    
                }else if currentState == ._EVENING_HABIT_{
                    if isHighPrioritySequenceGoing{
                        if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                            mainViewControllerObj?.showPasswordView()
                            enterPasswordVcObj?.parentVc = self
                        }else{
                            skipActivityAlreadyDid()
                        }
                    }else{
                        if SettingsManagerObject.isPasswordRequireInSkipEvening{
                            mainViewControllerObj?.showPasswordView()
                            enterPasswordVcObj?.parentVc = self
                        }else{
                            skipActivityAlreadyDid()
                        }
                    }
                    
                }else if currentState == ._CUSTOM_ROUTINE_{
                    skipActivityAlreadyDid()
                }
            }else{
                skipActivityAlreadyDid()
            }
        }
        
        
    }
    @IBAction func btnCanNotDoItClicked(_ sender: Any) {
        addLog(text: "[user-action] whySkipHabitVc:- button CanNotDoItClicked")
        self.view.removeFromSuperview()
        
        if currentState == ._MICRO_BREAK_{
            getHabitsVcObject().showSkipHabitView()
        }else{
            if shouldAskPassword(){
                if currentState == ._MORNING_HABIT_{
                    if SettingsManagerObject.isPasswordRequireInSkipMorning{
                        mainViewControllerObj?.showPasswordView()
                        enterPasswordVcObj?.parentVc = getSkipHabitVcObject()
                    }else{
                        getHabitsVcObject().showSkipHabitView()
                    }
                    
                }else if currentState == ._EVENING_HABIT_{
                    if isHighPrioritySequenceGoing{
                        if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                            mainViewControllerObj?.showPasswordView()
                            enterPasswordVcObj?.parentVc = getSkipHabitVcObject()
                        }else{
                            getHabitsVcObject().showSkipHabitView()
                        }
                    }else{
                        if SettingsManagerObject.isPasswordRequireInSkipEvening{
                            mainViewControllerObj?.showPasswordView()
                            enterPasswordVcObj?.parentVc = getSkipHabitVcObject()
                        }else{
                            getHabitsVcObject().showSkipHabitView()
                        }
                    }
                }else if currentState == ._CUSTOM_ROUTINE_{
                    getHabitsVcObject().showSkipHabitView()
                }
            }else{
                getHabitsVcObject().showSkipHabitView()
            }
        }
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        addLog(text: "[user-action] whySkipHabitVc:- button CloseClicked")
        self.view.removeFromSuperview()
    }
    
    @IBAction func btnSkipCompletelyClicked(_ sender: Any) {
        addLog(text: "[user-action] whySkipHabitVc - Skip Break Activities Completely Clicked")
        self.view.removeFromSuperview()
        getHabitsVcObject().postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil, isFromBreakWarningWindow: false)
    }
}
