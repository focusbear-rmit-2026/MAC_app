//
//  thirdVc.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 04/01/22.
//  .
//

import Cocoa

class thirdVc: NSViewController {
    
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var boxBreathingFinished: NSBox!
    @IBOutlet weak var btnMain: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var lblProgress: NSTextField!
    
    var randomIntToRememberNextHabit: Int = 0
    var lastHabitIndex = -1
    var lastActivityIndex = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Smile _Small")
            imgViewGif.animates = true
        }
        
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
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
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
        
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits - habitCompletedSeconds)
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
        
        
        var totalMinutesString: String = ""
        
        
        if h != 0{
            habitMinutesString = "\(h)h"
        }
        if m != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(m)m"
            }else{
                habitMinutesString += " \(m)m"
            }
        }
        if s != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(s)s"
            }else{
                habitMinutesString += " \(s)s"
            }
        }
        
        if hour != 0{
            totalMinutesString = "\(hour)h"
        }
        if minute != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(minute)m"
            }else{
                totalMinutesString += " \(minute)m"
            }
        }
        if second != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(second)s"
            }else{
                totalMinutesString += " \(second)s"
            }
        }
        
        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                   finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                   finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            lblProgress.stringValue = finalSring
        }
        
        
        
        
        
        if index < arrAllMorningHabits.count-1 {
            
            imgViewGif.isHidden = true
            playEveryActivitySound()
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            
            
            if isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                               btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else {
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            btnMain.toolTip = btnMain.title
            playAfterMorningRoutineSound()
        }
    }
    
    func eveningHabitFinished(index:Int) {
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
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
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits - habitCompletedSeconds)
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
        var totalMinutesString: String = ""
        if h != 0{
            habitMinutesString = "\(h)h"
        }
        if m != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(m)m"
            }else{
                habitMinutesString += " \(m)m"
            }
        }
        if s != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(s)s"
            }else{
                habitMinutesString += " \(s)s"
            }
        }
        
        if hour != 0{
            totalMinutesString = "\(hour)h"
        }
        if minute != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(minute)m"
            }else{
                totalMinutesString += " \(minute)m"
            }
        }
        if second != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(second)s"
            }else{
                totalMinutesString += " \(second)s"
            }
        }
        
        

        
        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                   finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                   finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            lblProgress.stringValue = finalSring
        }
        
        
        lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
        playEveryActivitySound()
        
        if isPromptToRememberHabit{
            if !isPromptToRememberHabitShowedInLastHabit{
                randomIntToRememberNextHabit = Int.random(in: 0..<6)
                if randomIntToRememberNextHabit == 5{
                    isPromptToRememberHabitShowedInLastHabit = true
                    btnMain.title = "What comes next?"
                    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                           btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                    }
                    btnMain.toolTip = btnMain.title
                }else{
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                isPromptToRememberHabitShowedInLastHabit = false
                let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else{
            let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
            btnMain.toolTip = btnMain.title
        }
        
        
    }
    
    func activityFinished(index:Int) {
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
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
                logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
                durationInSeconds = arrActivitiesIncludeInEveryBreak[lastActivityIndex].durationSeconds
                logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrActivitiesIncludeInEveryBreak[lastActivityIndex].logQuantityQuestion
            }else{
                lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].name
                logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
                durationInSeconds = arrActivitiesExcludeInEveryBreak[lastActivityIndex].durationSeconds
                logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].logQuantityQuestion
            }
        }else{
            lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrAllbreakActivities[lastActivityIndex].name
            logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
            durationInSeconds = arrActivitiesExcludeInEveryBreak[lastActivityIndex].durationSeconds
            logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrAllbreakActivities[lastActivityIndex].logQuantityQuestion
        }
        
        if logQuantity{
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.resetData(name: lastActivity, durationInSeconds: "\(durationInSeconds)", logQuantityQuestion: logQuantityQuestion, currentState: ._ACTIVITY_)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "break", activity: lastActivity, durationInSeconds: "\(durationInSeconds)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
        }
        
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                
                if index < arrActivitiesIncludeInEveryBreak.count-1 {
                    lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                    currentActivity = arrActivitiesIncludeInEveryBreak[lastActivityIndex+1]
                }else {
                    if arrActivitiesExcludeInEveryBreak.count == 0{
                        lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                        btnMain.title = unlockMachineButtonText
                        btnMain.toolTip = btnMain.title
                        imgViewGif.isHidden = false
                    }else{
                        lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                        currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
                        currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                    }
                }
            }else{
                lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                btnMain.title = unlockMachineButtonText
                btnMain.toolTip = btnMain.title
                imgViewGif.isHidden = false
            }
        }else{
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
            btnMain.title = unlockMachineButtonText
            btnMain.toolTip = btnMain.title
            imgViewGif.isHidden = false
        }

        
        if currentActivity != nil{
            
            var nextActivityName: String = ""
            
            
            if !currentActivity!.isRandomChoice{
                nextActivityName = currentActivity!.name
            }else{//random choice
                currentActivityChoice = currentActivity?.choices.randomElement()
                
                if currentActivity?.choices.count != 1{
                    if let lastChoice = lastShownRandomChoiceDic[currentActivity!.name]{
                        while lastChoice.name == currentActivityChoice!.name && lastChoice.logQuantityQuestion == currentActivityChoice!.logQuantityQuestion{
                            currentActivityChoice = currentActivity?.choices.randomElement()
                        }
                    }
                }
                
                
                lastShownRandomChoiceDic[currentActivity!.name ?? ""] = currentActivityChoice
                nextActivityName = currentActivityChoice?.name ?? ""
            }
            
            
            let time = currentActivity!.durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: nextActivityName)
            btnMain.toolTip = btnMain.title
        }
        playEveryActivitySound()
    }
    
    var currentActivityChoice:activityChoice?
    func startBreakActivity() {
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
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
            currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
        }
        
        
        if !currentActivity!.isRandomChoice{
            activityName = currentActivity!.name
        }else{//random choice
            currentActivityChoice = currentActivity?.choices.randomElement()
            
            if currentActivity?.choices.count != 1{
                if let lastChoice = lastShownRandomChoiceDic[currentActivity!.name]{
                    while lastChoice.name == currentActivityChoice!.name && lastChoice.logQuantityQuestion == currentActivityChoice!.logQuantityQuestion{
                        currentActivityChoice = currentActivity?.choices.randomElement()
                    }
                }
            }
            
            
            lastShownRandomChoiceDic[currentActivity!.name ?? ""] = currentActivityChoice
            
            activityName = currentActivityChoice?.name ?? ""
        }
        
        seconds = currentActivity!.durationSeconds
        
        lblTitle.stringValue = getStartBreakActivityTitleText(seconds: seconds, activityName: activityName)//"It’s time for a break. Do \(seconds) seconds of \(activityName) to earn more screentime."
        btnMain.title = getstartActivityButtonText(seconds: seconds, name: activityName)//"Start \(seconds) seconds \(activityName)"
        btnMain.toolTip = btnMain.title
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
                        mainViewControllerObj?.activityFinishedUnlockMachine()
                    }
                }else{
                    mainViewControllerObj?.activityFinishedUnlockMachine()
                }
            }
            
        }else if currentState == ._MORNING_HABIT_{
            if lastHabitIndex < arrAllMorningHabits.count-1 {
                if randomIntToRememberNextHabit == 5{
                    boxBg.isHidden = true
                    getRememberNextHabitVcObj().nextHabitIndex = lastHabitIndex+1
                    self.view.addSubview(getRememberNextHabitVcObj().view)
                    self.view.addConstraints(subView: getRememberNextHabitVcObj().view)
                    getRememberNextHabitVcObj().resetData()
                    randomIntToRememberNextHabit = 0
                }else{
                    mainViewControllerObj?.changeMorningHabit()
                }
            }else {
                mainViewControllerObj?.habitsFinishedUnlockMachine()
            }
        }else if currentState == ._EVENING_HABIT_{
            if lastHabitIndex < arrAllEveningHabits.count-1 {
                if randomIntToRememberNextHabit == 5{
                    boxBg.isHidden = true
                    getRememberNextHabitVcObj().nextHabitIndex = lastHabitIndex+1
                    self.view.addSubview(getRememberNextHabitVcObj().view)
                    self.view.addConstraints(subView: getRememberNextHabitVcObj().view)
                    getRememberNextHabitVcObj().resetData()
                    randomIntToRememberNextHabit = 0
                }else{
                    mainViewControllerObj?.changeEveningHabit()
                }
            }else {
                mainViewControllerObj?.habitsFinishedUnlockMachine()//ye call ni hoga
            }
        }
    }
}





