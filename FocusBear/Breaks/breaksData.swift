//
//  breaksData.swift
//  FocusBear
//
//  Created by Manish Jain on 17/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var breakAfterMinutes = 0
var arrAllbreakActivities = [breakActivity]()
var arrFinalBreakActivities = [breakActivityFilter]()
struct breakActivityFilter{
    var activity:breakActivity!
    var randomChoice:activityChoice?
}

struct breakActivity {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var IncludeInEveryBreak:Bool!
    var urlsArray:[String]
    var logQuantity:Bool!
    var choiceType:CHOICETYPE!
    var choices:[activityChoice]
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var isOfficeFriendly:Bool!
    var allowedFocusMode:String!
    var logQuantityType:String!
    var activity_sequence_id:String!
    var take_notes:String!
    var text_instructions = ""
    var imgUrls = [String]()
    var completion_requirements = ""
    var useTimer:Bool = true
    var logQuantityQuestions = [quantityQuestion]()
    var checkList = [String]()
    init(id:String, name:String, durationSeconds:Int, IncludeInEveryBreak:Bool, urlsArray:[String], logQuantity:Bool,choiceType:CHOICETYPE,choices:[activityChoice],logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],isOfficeFriendly:Bool,allowedFocusMode:String,logQuantityType:String,activity_sequence_id:String,take_notes:String, text_instructions:String, imgUrls:[String], completion_requirements:String, useTimer:Bool, checkList:[String]) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.IncludeInEveryBreak = IncludeInEveryBreak
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.choiceType = choiceType
        self.choices = choices
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.isOfficeFriendly = isOfficeFriendly
        self.allowedFocusMode = allowedFocusMode
        self.logQuantityType = logQuantityType
        self.activity_sequence_id = activity_sequence_id
        self.take_notes = take_notes
        self.text_instructions = text_instructions
        self.imgUrls = imgUrls
        self.completion_requirements = completion_requirements
        self.useTimer = useTimer
        self.checkList = checkList
    }
}


func checkNaturalBreakFromIdleTimeAfterScreenUnlocked(){
    addLog(text: "func checkNaturalBreakFromIdleTimeAfterScreenUnlocked")
    closeNatutalBreakIfRunning()
    if !SettingsManagerObject.isDetectNatualBreaksEnabled{
        addLog(text: "Detect Natual Breaks is not enabled")
        return;
    }
    
    if macGoesInSleepTime != nil{
        let idleTimeValue = Calendar.current.dateComponents([.second], from: macGoesInSleepTime!, to: Date()).second ?? 0
        addLog(text: "idleTimeValue is :- \(idleTimeValue)")
        if arrAllbreakActivities.count != 0 && currentState != ._BREATHING_{
            addLog(text: "checkIsNaturalBreakWindowNeedToShow")
            
            
            if idleTimeValue > idleTimeValueForNaturalBreak{
                UserDefaults.standard.set(macGoesInSleepTime!, forKey: kUserdefaultsLastBreaksStartTime)
                writeNaturalBreak()//2.28.444
            }
        }else{
            addLog(text: "Don't need to check natural break reason:- habit window is visible")
        }
    }else{
        addLog(text: "macGoesInSleepTime is nil")
    }
}

func writeNaturalBreak(){//2.28.444
    if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
        let currentDate = Date()
        let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
        if diffSeconds > 0{
            var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
            arrDuration.append(diffSeconds)
            UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
        }
        UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = df.string(from: currentDate)
        addLog(text: "Last break recorded at \(now). It will be shown in the menu.")
        print("\(diffSeconds) seconds Last break recorded at \(now). It will be shown in the menu.")
        if currentState != ._MICRO_BREAK_{
            if getHabitsVcObject().breakTimer != nil{
                getHabitsVcObject().setActivityTimer()
            }
        }
    }
}


let idleTimeValueForNaturalBreak = 120// edited from 600 to 120  2.28.444  //
var anyNaturallBreakIsOn = false
func detectNatualBreaks(){
    if !SettingsManagerObject.isDetectNatualBreaksEnabled{
        return;
    }
    var lastEvent:CFTimeInterval = 0
    lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
    
    let idleTimeValue = Int(lastEvent)
    if currentState != ._MORNING_HABIT_ && currentState != ._MICRO_BREAK_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !appdelegate!.isUserOnMeeting{
        checkIsNaturalBreakStarted(idleTimeValue: idleTimeValue)
    }else{
        closeNatutalBreakIfRunning()
    }
}

func checkIsNaturalBreakStarted(idleTimeValue:Int){
    print(idleTimeValue)
    if idleTimeValue > idleTimeValueForNaturalBreak{
        if anyNaturallBreakIsOn{
            return;
        }
        var shouldShowAlert = true
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            if !SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                addLog(text: "The current state is 'Postpone' and 'Show Breaks in Postpone' is disabled, so the natural break detection window will not be shown.")// logs addded in v 1.26.395 on 30/7/25
                shouldShowAlert = false
            }
        }
        if shouldShowAlert{
            if appdelegate!.checkIsAnyVideoWebsiteIsRunning(){
                addLog(text: "Since a video website is currently open in the browser, the natural break detection window won't be shown.")
                shouldShowAlert = false
            }
        }
        if shouldShowAlert{
            if isAnyPresentationOrVideoShowing(){
                addLog(text: "Since a presentation or video is showing in the browser, the natural break detection window won't be shown.")
                shouldShowAlert = false
            }
        }
        
        if shouldShowAlert{
            anyNaturallBreakIsOn = true
            let idelTimeStartTime = Date().addingTimeInterval(-Double(idleTimeValue))
            UserDefaults.standard.set(idelTimeStartTime, forKey: kUserdefaultsLastBreaksStartTime)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let now = df.string(from: idelTimeStartTime)
            addLog(text: "Naturall break started at \(now).")
            print("Naturall break started at \(now).")
        }
    }else{
        closeNatutalBreakIfRunning()
    }
}

func closeNatutalBreakIfRunning(){
    if anyNaturallBreakIsOn{
        anyNaturallBreakIsOn = false
        writeNaturalBreak()
    }
}

func getTimeSinceLastBreak()->String?{
    var breaksEndTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakEndTime) as? Date
    if breaksEndTime == nil{
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        breaksEndTime = startDate
    }else{
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        
        if breaksEndTime!.compare(startDate) == .orderedAscending {//breaksStartTime < start date
            breaksEndTime = startDate
        }
    }
    if let breaksEndTime = breaksEndTime{
        let currentDate = Date()
        let diffSeconds = Calendar.current.dateComponents([.second], from: breaksEndTime, to: currentDate).second ?? 0
        if diffSeconds > 0{
            let time = getStringTimeFromSecondsWithoutSeconds(seconds: Int(diffSeconds))
            var lastBreakTimeText = "Time since last break: <TIME>"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                lastBreakTimeText = menuInfo.value(forKey: "lastBreakTimeText") as? String ?? lastBreakTimeText
            }
            lastBreakTimeText = lastBreakTimeText.replacingOccurrences(of: "<TIME>", with: time)
            return lastBreakTimeText
        }
    }
    return nil
}
