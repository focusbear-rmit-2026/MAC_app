//
//  thirdVc.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 04/01/22.
//  .
//

import Cocoa

class thirdVc: NSViewController {
    
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var boxBreathingFinished: NSBox!
    @IBOutlet weak var btnMain: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    
    
    var lastHabitIndex = -1
    var lastActivityIndex = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        imgViewGif.image = NSImage(named: "Smile _Small")
        imgViewGif.animates = true
        boxBreathingFinished.isHidden = true
        var string = "Hope you feel calmer. You can now personalise your morning routine by clicking on the icon <icon> on the top bar and choosing settings."
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            if let subTitle = dic.value(forKey: "welcomeEndMessage") as? String{
                string = subTitle
            }
        }
        lblSubTitle.attributedStringValue = attechIconWithString(text: string)
    }
    
    func breathingFinished() {
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = false
        var name = "Breathing"
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                name = arr.first?.value(forKey: "name") as? String ?? ""
            }else{

            }
        }
        lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: name)//"Breathing finished!✅ You’ve earned your screen time. 💪"
        btnMain.title = unlockMachineButtonText
    }
    func morningHabitFinished(index:Int) {
        
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrAllMorningHabits[lastHabitIndex].name
        
        if index < arrAllMorningHabits.count-1 {
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
            playEveryActivitySound()
            imgViewGif.isHidden = true
        }else {
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            playAfterMorningRoutineSound()
        }
    }
    func eveningHabitFinished(index:Int) {
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrAllEveningHabits[lastHabitIndex].name
        
//        if index < arrAllEveningHabits.count-1 {
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
            playEveryActivitySound()
//        }else {
//            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
//            btnMain.title = unlockMachineButtonText
//            playAfterMorningRoutineSound()
//        }
    }
    
    func activityFinished(index:Int) {
        boxBreathingFinished.isHidden = true
        imgViewGif.isHidden = true
        lastActivityIndex = index
        var lastActivity = ""//arrAllbreakActivities[lastActivityIndex].name
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                lastActivity = arrActivitiesIncludeInEveryBreak[lastActivityIndex].name
            }else{
                lastActivity = arrActivitiesExcludeInEveryBreak[lastActivityIndex].name
            }
        }else{
           lastActivity = arrAllbreakActivities[lastActivityIndex].name
        }
        if showEveryBreak{
            if index < arrAllbreakActivities.count-1 {
                lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                let time = arrAllbreakActivities[lastActivityIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllbreakActivities[lastActivityIndex+1].name!)//"Start \(time!) seconds \(arrAllbreakActivities[lastActivityIndex+1].name!)"
            }else {
                lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                btnMain.title = unlockMachineButtonText
                imgViewGif.isHidden = false
            }
        }else{
            if isAnyMandatoryActivityIncluded{
                if isMandatoryActivityGoing{
                    
                    if index < arrActivitiesIncludeInEveryBreak.count-1 {
                        lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                        let time = arrActivitiesIncludeInEveryBreak[lastActivityIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrActivitiesIncludeInEveryBreak[lastActivityIndex+1].name!)//"Start \(time!) seconds \(arrActivitiesIncludeInEveryBreak[lastActivityIndex+1].name!)"
                    }else {
                        if arrActivitiesExcludeInEveryBreak.count == 0{
                            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                            btnMain.title = unlockMachineButtonText
                            imgViewGif.isHidden = false
                        }else{
                            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                          //  isMandatoryActivityGoing = false
                            currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
                            let time = arrActivitiesExcludeInEveryBreak[currentActivityIndex].durationSeconds
                            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!)//"Start \(time!) seconds \(arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!)"
                        }
                    }
                }else{
                   // if index < arrActivitiesExcludeInEveryBreak.count-1 {
                   //     lblTitle.stringValue = "\(lastActivity) finished!✅"
                   //     let time = arrActivitiesExcludeInEveryBreak[lastActivityIndex+1].durationSeconds
                   //     btnMain.title = "Start \(time!) seconds \(arrActivitiesExcludeInEveryBreak[lastActivityIndex+1].name!)"
                   // }else{
                        lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                        btnMain.title = unlockMachineButtonText
                    imgViewGif.isHidden = false
                    //}
                }
            }else{
               lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
               btnMain.title = unlockMachineButtonText
                imgViewGif.isHidden = false
            }
            
        }
        playEveryActivitySound()
    }
    
    func startBreakActivity() {
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        lastActivityIndex = -1
        var activityName: String = ""
        var seconds: Int = 0
        if isMandatoryActivityGoing{
            activityName = arrActivitiesIncludeInEveryBreak[currentActivityIndex].name
            seconds = arrActivitiesIncludeInEveryBreak[currentActivityIndex].durationSeconds
        }else{
            activityName = arrAllbreakActivities[currentActivityIndex].name
            seconds = arrAllbreakActivities[currentActivityIndex].durationSeconds
        }
        lblTitle.stringValue = getStartBreakActivityTitleText(seconds: seconds, activityName: activityName)//"It’s time for a break. Do \(seconds) seconds of \(activityName) to earn more screentime."
        btnMain.title = getstartActivityButtonText(seconds: seconds, name: activityName)//"Start \(seconds) seconds \(activityName)"
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        if currentState == ._BREATHING_{
            boxBreathingFinished.isHidden = true
            mainViewControllerObj?.breathingFinishedUnlockMachine()
        }else if currentState == ._ACTIVITY_ {
            if lastActivityIndex == -1 {
                mainViewControllerObj?.startCurrentActivity()
            }else{
                if showEveryBreak{
                    if lastActivityIndex < arrAllbreakActivities.count-1 {
                        mainViewControllerObj?.changeActivity()
                    }else {
                        mainViewControllerObj?.activityFinishedUnlockMachine()
                    }
                }else{
                    if isAnyMandatoryActivityIncluded{
                        if isMandatoryActivityGoing{
                            
                            if lastActivityIndex < arrActivitiesIncludeInEveryBreak.count-1 {
                                mainViewControllerObj?.changeActivity()
                            }else {
                                if arrActivitiesExcludeInEveryBreak.count == 0{
                                    mainViewControllerObj?.activityFinishedUnlockMachine()
                                }else{
                                    isMandatoryActivityGoing = false
                                    mainViewControllerObj?.changeActivity()
                                }
                            }
                        }else{
//                            if lastActivityIndex < arrActivitiesExcludeInEveryBreak.count-1 {
//                                mainViewControllerObj?.changeActivity()
//                            }else{
                                mainViewControllerObj?.activityFinishedUnlockMachine()
                           // }
                        }
                    }else{
                        mainViewControllerObj?.activityFinishedUnlockMachine()
                    }
                    
                    
                }
                
            }
            
        }else if currentState == ._MORNING_HABIT_{
            if lastHabitIndex < arrAllMorningHabits.count-1 {
                mainViewControllerObj?.changeMorningHabit()
            }else {
                mainViewControllerObj?.habitsFinishedUnlockMachine()
            }
        }else if currentState == ._EVENING_HABIT_{
            if lastHabitIndex < arrAllEveningHabits.count-1 {
                mainViewControllerObj?.changeEveningHabit()
            }else {
                mainViewControllerObj?.habitsFinishedUnlockMachine()
            }
        }
    }
}
