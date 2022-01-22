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

    
    var lastHabitIndex = -1
    var lastActivityIndex = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
    func habitFinished(index:Int) {
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrAllHabits[lastHabitIndex].name
        
        
        if index < arrAllHabits.count-1 {
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            let time = arrAllHabits[lastHabitIndex+1].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllHabits[lastHabitIndex+1].name!)
//            if time! < 60{
//                btnMain.title = getstartActivityButtonText(seconds: "\(time!) seconds", name: arrAllHabits[lastHabitIndex+1].name!)//"Start \(time!) seconds \(arrAllHabits[lastHabitIndex+1].name!)"
//            }else{
//                let minutes = time!/60
//                if minutes == 1 {
//                    btnMain.title = getstartActivityButtonText(seconds: "\(minutes) minute", name: arrAllHabits[lastHabitIndex+1].name!)//"Start \(minutes) minute \(arrAllHabits[lastHabitIndex+1].name!)"
//                }else {
//                    btnMain.title = getstartActivityButtonText(seconds: "\(minutes) minutes", name: arrAllHabits[lastHabitIndex+1].name!)//"Start \(minutes) minutes \(arrAllHabits[lastHabitIndex+1].name!)"
//                }
//            }
            playEveryActivitySound()
        }else {
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)//"\(lastHabit!) finished!✅ You’ve earned your screen time. 💪"
            btnMain.title = unlockMachineButtonText
            playAfterMorningRoutineSound()
//            DispatchQueue.global().async {
//                sleep(2)
//                DispatchQueue.main.async {
//                    appdelegate?.shutOffMac()
//                }
//            }
        }
        
    }
    func activityFinished(index:Int) {
        boxBreathingFinished.isHidden = true
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
                    //}
                }
            }else{
               lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
               btnMain.title = unlockMachineButtonText
            }
            
        }
        playEveryActivitySound()
    }
    
    func startBreakActivity() {
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
        boxBreathingFinished.isHidden = true
        if isBreathingGoing{
            boxBreathingFinished.isHidden = true
            mainViewControllerObj?.breathingFinishedUnlockMachine()
        }else if isBreakActivitiesGoing {
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
            
        }else {
            if lastHabitIndex < arrAllHabits.count-1 {
                mainViewControllerObj?.changeHabit()
            }else {
                mainViewControllerObj?.habitsFinishedUnlockMachine()
            }
        }
    }
}
