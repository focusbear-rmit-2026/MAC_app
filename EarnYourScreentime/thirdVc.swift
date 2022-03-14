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
    @IBOutlet weak var lblProgress: NSTextField!
    
    
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
        lblProgress.isHidden = true
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
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrAllMorningHabits[lastHabitIndex].name
        if arrAllMorningHabits[lastHabitIndex].logQuantity{
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(arrAllMorningHabits[lastHabitIndex].durationSeconds!)", logQuantityQuestion: arrAllMorningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._MORNING_HABIT_)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "morning routine", activity: lastHabit!, durationInSeconds: "\(arrAllMorningHabits[lastHabitIndex].durationSeconds!)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
        }
        var totalSecondsAllHabits = 0
        var habitCompletedSeconds = 0
        
        
        for i in 0..<arrAllMorningHabits.count{
            totalSecondsAllHabits += arrAllMorningHabits[i].durationSeconds
            if i<=index{
                habitCompletedSeconds += arrAllMorningHabits[i].durationSeconds
            }
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: habitCompletedSeconds)
        var habitHour = "\(h)"
        var habitMinute = "\(m)"
        var habitSecond = "\(s)"
        
        if habitHour.count == 1 {
            habitHour = "0\(h)"
        }
        
        if habitMinute.count == 1 {
            habitMinute = "0\(m)"
        }
        if habitSecond.count == 1 {
            habitSecond = "0\(s)"
        }
        
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits)
        var totalHour = "\(hour)"
        var totalMinute = "\(minute)"
        var totalSecond = "\(second)"
        
        if totalHour.count == 1 {
            totalHour = "0\(hour)"
        }
        if totalMinute.count == 1 {
            totalMinute = "0\(minute)"
        }
        if totalSecond.count == 1 {
            totalSecond = "0\(second)"
        }
        
        var habitMinutesString: String = ""
//        var hoursString = "hours"
//        var minutesString = "minutes"//read from config file //
//        var secondsString = "seconds"
        
        
//        minutesString = (m == 1) ? "minute" : "minutes"
//
//        secondsString = (s == 1) ? "second" : "seconds"
//
//        hoursString = (h == 1) ? "hour" : "hours"

//        if h == 0{
//            habitMinutesString = "\(habitMinute) \(minutesString) \(habitSecond) \(secondsString)"
//        }else{
//            habitMinutesString = "\(habitHour) \(hoursString) \(habitMinute) \(minutesString) \(habitSecond) \(secondsString)"
//        }
//        habitMinutesString = (h == 0) ? "\(habitMinute) \(minutesString) \(habitSecond) \(secondsString)" : "\(habitHour) \(hoursString) \(habitMinute) \(minutesString) \(habitSecond) \(secondsString)"
        habitMinutesString = "\(habitHour):\(habitMinute):\(habitSecond)"
        
        var totalMinutesString: String = ""
        
//        minutesString = (minute == 1) ? "minute" : "minutes"
//
//        secondsString = (second == 1) ? "second" : "seconds"
//
//        hoursString = (hour == 1) ? "hour" : "hours"

//        totalMinutesString = "\(totalMinute) \(minutesString) \(totalSecond) \(secondsString)"
        
//        totalMinutesString = (hour == 0) ? "\(totalMinute) \(minutesString) \(totalSecond) \(secondsString)" : "\(totalHour) \(hoursString) \(totalMinute) \(minutesString) \(totalSecond) \(secondsString)"
        
        totalMinutesString = "\(totalHour):\(totalMinute):\(totalSecond)"
        
//        lblProgress.stringValue = "\(habitMinutesString)/\(totalMinutesString) Completed"
        //You have completed 00:20:00 of 01:45:00 minutes of activities
        lblProgress.stringValue = "You have completed \(habitMinutesString) of \(totalMinutesString) duration of activities."
        
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
        lblProgress.isHidden = false
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrAllEveningHabits[lastHabitIndex].name
        if arrAllEveningHabits[lastHabitIndex].logQuantity{
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(arrAllEveningHabits[lastHabitIndex].durationSeconds!)", logQuantityQuestion: arrAllEveningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._EVENING_HABIT_)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "evening routine", activity: lastHabit!, durationInSeconds: "\(arrAllEveningHabits[lastHabitIndex].durationSeconds!)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
        }
        
        var totalSecondsAllHabits = 0
        var habitCompletedSeconds = 0
        
        
        for i in 0..<arrAllEveningHabits.count{
            totalSecondsAllHabits += arrAllEveningHabits[i].durationSeconds
            if i<=index{
                habitCompletedSeconds += arrAllEveningHabits[i].durationSeconds
            }
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: habitCompletedSeconds)
        var habitHour = "\(h)"
        var habitMinute = "\(m)"
        var habitSecond = "\(s)"
        
        if habitHour.count == 1 {
            habitHour = "0\(h)"
        }
        
        if habitMinute.count == 1 {
            habitMinute = "0\(m)"
        }
        if habitSecond.count == 1 {
            habitSecond = "0\(s)"
        }
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits)
        var totalHour = "\(hour)"
        var totalMinute = "\(minute)"
        var totalSecond = "\(second)"
        
        if totalHour.count == 1 {
            totalHour = "0\(hour)"
        }
        
        if totalMinute.count == 1 {
            totalMinute = "0\(minute)"
        }
        if totalSecond.count == 1 {
            totalSecond = "0\(second)"
        }
        var habitMinutesString: String = ""
        var hoursString = "hours"
        var minutesString = "minutes"
        var secondsString = "seconds"
        
        minutesString = (m == 1) ? "minute" : "minutes"

        secondsString = (s == 1) ? "second" : "seconds"
        
        hoursString = (h == 1) ? "hour" : "hours"

//        habitMinutesString = "\(habitMinute) \(minutesString) \(habitSecond) \(secondsString)"
//        habitMinutesString = (h == 0) ? "\(habitMinute) \(minutesString) \(habitSecond) \(secondsString)" : "\(habitHour) \(hoursString) \(habitMinute) \(minutesString) \(habitSecond) \(secondsString)"
        habitMinutesString = "\(habitHour):\(habitMinute):\(habitSecond)"
        
        var totalMinutesString: String = ""
        
        minutesString = (minute == 1) ? "minute" : "minutes"

        secondsString = (second == 1) ? "second" : "seconds"
        
        hoursString = (hour == 1) ? "hour" : "hours"
        

//        totalMinutesString = "\(totalMinute) \(minutesString) \(totalSecond) \(secondsString)"
        
//        totalMinutesString = (hour == 0) ? "\(totalMinute) \(minutesString) \(totalSecond) \(secondsString)" : "\(totalHour) \(hoursString) \(totalMinute) \(minutesString) \(totalSecond) \(secondsString)"
        totalMinutesString = "\(totalHour):\(totalMinute):\(totalSecond)"
        
//        lblProgress.stringValue = "\(habitMinutesString)/\(totalMinutesString) Completed"
        
        lblProgress.stringValue = "You have completed \(habitMinutesString) of \(totalMinutesString) duration of activities."
        
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
        lblProgress.isHidden = true
        currentActivityChoice = nil
        var currentActivity:breakActivity?
        boxBreathingFinished.isHidden = true
        imgViewGif.isHidden = true
        lastActivityIndex = index
        var lastActivity = ""//arrAllbreakActivities[lastActivityIndex].name
        var logQuantity:Bool = false
        var durationInSeconds = 0
        var logQuantityQuestion:String?
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrActivitiesIncludeInEveryBreak[lastActivityIndex].name//because name mai activitychoice ka name bhi ho skta h
                logQuantity = arrActivitiesIncludeInEveryBreak[lastActivityIndex].logQuantity
                durationInSeconds = arrActivitiesIncludeInEveryBreak[lastActivityIndex].durationSeconds
                logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrActivitiesIncludeInEveryBreak[lastActivityIndex].logQuantityQuestion
            }else{
                lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].name
                logQuantity = arrActivitiesExcludeInEveryBreak[lastActivityIndex].logQuantity
                durationInSeconds = arrActivitiesExcludeInEveryBreak[lastActivityIndex].durationSeconds
                logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].logQuantityQuestion
            }
        }else{
            lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrAllbreakActivities[lastActivityIndex].name
            logQuantity = arrAllbreakActivities[lastActivityIndex].logQuantity
            durationInSeconds = arrAllbreakActivities[lastActivityIndex].durationSeconds
            logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrAllbreakActivities[lastActivityIndex].logQuantityQuestion
        }
        
        if logQuantity{
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.resetData(name: lastActivity, durationInSeconds: "\(durationInSeconds)", logQuantityQuestion: logQuantityQuestion, currentState: ._ACTIVITY_)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "break", activity: lastActivity, durationInSeconds: "\(durationInSeconds)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
        }
        
        if showEveryBreak{
            if index < arrAllbreakActivities.count-1 {
                lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
//                let time = arrAllbreakActivities[lastActivityIndex+1].durationSeconds
//                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllbreakActivities[lastActivityIndex+1].name!)
                currentActivity = arrAllbreakActivities[lastActivityIndex+1]
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
//                        let time = arrActivitiesIncludeInEveryBreak[lastActivityIndex+1].durationSeconds
//                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrActivitiesIncludeInEveryBreak[lastActivityIndex+1].name!)
                        currentActivity = arrActivitiesIncludeInEveryBreak[lastActivityIndex+1]
                    }else {
                        if arrActivitiesExcludeInEveryBreak.count == 0{
                            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                            btnMain.title = unlockMachineButtonText
                            imgViewGif.isHidden = false
                        }else{
                            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                            currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
//                            let time = arrActivitiesExcludeInEveryBreak[currentActivityIndex].durationSeconds
//                            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!)
                            currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                        }
                    }
                }else{
                    lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                    btnMain.title = unlockMachineButtonText
                    imgViewGif.isHidden = false
                }
            }else{
               lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
               btnMain.title = unlockMachineButtonText
                imgViewGif.isHidden = false
            }
            
        }
        
        
        
        if currentActivity != nil{
            
            var nextActivityName: String = ""
            
            
            if !currentActivity!.isRandomChoice{
                nextActivityName = currentActivity!.name
            }else{//random choice
                currentActivityChoice = currentActivity?.choices.randomElement()
                nextActivityName = currentActivityChoice?.name ?? ""
            }
            
            
            let time = currentActivity!.durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: nextActivityName)
        }
        playEveryActivitySound()
    }
    var currentActivityChoice:activityChoice?
    func startBreakActivity() {
        lblProgress.isHidden = true
        currentActivityChoice = nil
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        lastActivityIndex = -1
        var activityName: String = ""
        var seconds: Int = 0
        var currentActivity:breakActivity?
        if isMandatoryActivityGoing{
            currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
        }else{
            currentActivity = arrAllbreakActivities[currentActivityIndex]
        }
        
        
        if !currentActivity!.isRandomChoice{
            activityName = currentActivity!.name
        }else{//random choice
            currentActivityChoice = currentActivity?.choices.randomElement()
            activityName = currentActivityChoice?.name ?? ""
        }
        
        seconds = currentActivity!.durationSeconds
        
        lblTitle.stringValue = getStartBreakActivityTitleText(seconds: seconds, activityName: activityName)//"It’s time for a break. Do \(seconds) seconds of \(activityName) to earn more screentime."
        btnMain.title = getstartActivityButtonText(seconds: seconds, name: activityName)//"Start \(seconds) seconds \(activityName)"
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
            if enterPasswordVcObj != nil{
                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                    return;
                }
            }
        }
        lblProgress.isHidden = true
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



