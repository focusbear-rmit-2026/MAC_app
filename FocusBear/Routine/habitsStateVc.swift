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
    
    var morningRoutinePostponedText = "Morning routine postponed. Resume it now by clicking 'Resume Habit'."
    var eveningRoutinePostponedText = "Evening routine postponed. Resume it now by clicking 'Resume Habit'."
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnResumeHabits.title = "Resume Habits"
        
        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
            morningRoutinePostponedText = habitsStateVcInfo.value(forKey: "morningRoutinePostponedText") as? String ?? morningRoutinePostponedText
            eveningRoutinePostponedText = habitsStateVcInfo.value(forKey: "eveningRoutinePostponedText") as? String ?? eveningRoutinePostponedText
            btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonResumeHabits") as? String ?? btnResumeHabits.title
        }
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
            
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = morningRoutinePostponedText
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
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
                let (nextRoutine, nextRoutineName) = getNextRoutineInfo()
                
                var timeFormat = "h:mm a"
                if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
                    print(dict)
                    if let isShow24Hour = dict["Show24Hour"] as? Bool {
                        if isShow24Hour{
                            timeFormat = "H:mm"
                        }
                    }
                }
                let (dateString) = getStringFromDate(date: nextRoutine, dateFormat: timeFormat)
                var nextRoutineText = "Great job staying on track! Your next scheduled routine (<ROUTINE>) is set for <TIME>. Be ready to jump back in and continue building those healthy habits. You've got this!"
                if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                    nextRoutineText = habitsStateVcInfo.value(forKey: "nextRoutineText") as? String ?? nextRoutineText
                }
                nextRoutineText = nextRoutineText.replacingOccurrences(of: "<ROUTINE>", with: nextRoutineName)
                nextRoutineText = nextRoutineText.replacingOccurrences(of: "<TIME>", with: dateString)
                lblTitle.stringValue = nextRoutineText
                
                
                
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                    if Date().compare(date) == .orderedAscending {
                        lblTitle.stringValue = "Shutoff aborted. Your computer is now accessible again."
                        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                            lblTitle.stringValue = habitsStateVcInfo.value(forKey: "shutoffAbortedText") as? String ?? lblTitle.stringValue
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        menuViewControllerObj?.btnResumeHabitsClicked(self)
    }
}
