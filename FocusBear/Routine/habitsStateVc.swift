//
//  habitsStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 07/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class habitsStateVc: NSViewController {

    @IBOutlet weak var btnResumeHabits: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var morningRoutinePostponedText = "Morning routine postponed. Resume it now by clicking 'Resume Habit'." // todo text
    var eveningRoutinePostponedText = "Evening routine postponed. Resume it now by clicking 'Resume Habit'." // todo text
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        reloadData()
    }
    
    func reloadData(){
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            btnResumeHabits.isHidden = false
            if currentState == ._POSTPON_MORNING_HABIT_{
                lblTitle.stringValue = morningRoutinePostponedText
            }else{
                lblTitle.stringValue = eveningRoutinePostponedText
            }
            
        }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = morningRoutinePostponedText
        }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeEveningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = eveningRoutinePostponedText
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = morningRoutinePostponedText
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = eveningRoutinePostponedText
        }else{
            btnResumeHabits.isHidden = true
            if isHabitAlreadyShowed && !isShutOffTimeGoing(){
                let nextRoutine = getNextRoutineTime()
                
                var timeFormat = "h:mm a"
                if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
                    print(dict)
                    if let isShow24Hour = dict["Show24Hour"] as? Bool {
                        if isShow24Hour{
                            timeFormat = "H:mm"
                        }
                    }
                }
                let dateString = getStringFromDate(date: nextRoutine, dateFormat: timeFormat)
                
                lblTitle.stringValue = "Great job staying on track! Your next scheduled routine is set for \(dateString). Be ready to jump back in and continue building those healthy habits. You've got this!" // todo text
            }
        }
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        menuViewControllerObj?.btnResumeHabitsClicked(self)
    }
}
