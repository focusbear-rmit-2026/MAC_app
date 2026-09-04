//
//  breaksData.swift
//  FocusBear
//
//  Created by Manish Jain on 17/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var breakAfterMinutes = 0
/// When a break comes due but can't be shown yet (in a meeting / focus session / presentation / active
/// blocking schedule / routine), we re-check after this many seconds instead of pushing the break out a
/// full `breakAfterMinutes` interval — so the break fires soon after the blocking condition clears.
let breakRetryWhenBlockedSeconds = 60
/// When the persisted next-break-due time is already reached (or passed) but a plain reschedule ran (e.g.
/// pause/resume landed after the break came due), re-check after this short delay so the break fires as
/// soon as conditions allow — WITHOUT resetting the due date to a full interval.
let breakRetryWhenDueSeconds = 15
/// How far past the due time counts as "stale" (app was closed a long time / overnight): overdue by more
/// than this many full `breakAfterMinutes` intervals starts a fresh interval instead of firing a break
/// right away, so a yesterday break doesn't spam moments after launch.
let breakStaleOverdueIntervalMultiple = 1.0

/// Formats a break's length for display. Short breaks read fine as a raw seconds count ("16 sec"), but
/// longer ones become awkward ("190 sec"), so anything over a minute is split into minutes + seconds
/// ("3 min 10 sec"). A whole number of minutes drops the trailing "0 sec" ("3 min").
func formatBreakDuration(_ seconds: Int) -> String {
    let secondsInMinute = 60
    let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary
    let minutesUnit = breakWarningVcInfo?.value(forKey: "durationMinutesUnit") as? String ?? "min"
    let secondsUnit = breakWarningVcInfo?.value(forKey: "durationSecondsUnit") as? String ?? "sec"
    if seconds <= secondsInMinute { return "\(seconds) \(secondsUnit)" }
    let minutes = seconds / secondsInMinute
    let remainderSeconds = seconds % secondsInMinute
    if remainderSeconds == 0 { return "\(minutes) \(minutesUnit)" }
    return "\(minutes) \(minutesUnit) \(remainderSeconds) \(secondsUnit)"
}

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
            // A natural break was just recorded, so reset the countdown to a fresh full interval — even
            // when breakTimer is currently nil. It usually IS nil here: the screen-lock/sleep that caused
            // the idle also PAUSED (stopped) the break timer, and this runs on unlock before it's
            // rescheduled. Without forcing the reset, the persisted next-break-due time from before the
            // lock survives and a break comes due again too soon after the user just took a real break.
            getHabitsVcObject().setActivityTimer(forceReset: true)   // a break was taken/recorded — reset to a full interval
        }
    }
}


let idleTimeValueForNaturalBreak = 120// edited from 600 to 120  2.28.444  //
var anyNaturallBreakIsOn = false
func detectNatualBreaks(){
    if !SettingsManagerObject.isDetectNatualBreaksEnabled{
        return;
    }
    let idleTimeValue = Int(secondsSinceLastUserInput())
//    if currentState != ._MORNING_HABIT_ && currentState != ._MICRO_BREAK_ && (isHabitAlreadyShowed || currentState == ._POSTPONE_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !appdelegate!.isUserOnMeeting{
//        checkIsNaturalBreakStarted(idleTimeValue: idleTimeValue)
//    }else{
//        closeNatutalBreakIfRunning()
//    }
//
    
    if currentState != ._MICRO_BREAK_ && arrAllbreakActivities.count != 0{
        checkIsNaturalBreakStarted(idleTimeValue: idleTimeValue)
    }else if appdelegate!.isUserOnMeeting{
        if SettingsManagerObject.IsShowBreaksInCallEnabled{
            checkIsNaturalBreakStarted(idleTimeValue: idleTimeValue)
        }else{
            closeNatutalBreakIfRunning()
        }
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
        if currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
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

/// Seconds since the last break ended, read from the persisted `kUserdefaultsLastBreakEndTime`
/// (which is updated by both real breaks and natural/idle breaks). Clamped to today's routine
/// start so time before the day began — or overnight after a restart — doesn't count.
/// Returns nil when there's no recorded break to carry over from.
func secondsSinceLastBreakEnd() -> Int? {
    guard let lastEnd = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakEndTime) as? Date else {
        return nil
    }
    var effective = lastEnd
    if let s = startTime {
        var startDate = Calendar.current.date(bySettingHour: s.hour, minute: s.minute, second: s.second, of: Date()) ?? Date()
        if Date() < startDate { startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate }
        if effective < startDate { effective = startDate }
    }
    let seconds = Int(Date().timeIntervalSince(effective))
    return seconds >= 0 ? seconds : nil
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
