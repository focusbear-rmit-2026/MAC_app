//
//  routine.swift
//  FocusBear
//
//  Created by Manish Jain on 28/03/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var isBreakActivityExecuteFromMorningHabit = false
var isBreakActivityExecuteFromEveningHabit = false

var isBreakActivityExecuteFromPostponeMorningHabit = false
var isBreakActivityExecuteFromPostponeEveningHabit = false

var currentHabitIndex = -1
var currentActivityIndex = -1
//var randomActivityIndex = 0
var currentActivityPlaying:breakActivity?
var currentHabitPlaying:habit?
var currentRelaxHabitPlaying:habit?

var additionalHabitTotalCompletedSeconds = 0// if user has comp[leted some activities in other device so we keep that activities duration in this variable to caluclate progess
var habitTotalCompletedSeconds = 0
var isProcessingCustomRoutine = false

var activityPostponeCount = 0
var activitySkipCount = 0
var isHabitsDisabled = false
var isHabitAlreadyShowed = true
var lastActivityPerformedTime:Date?
var postponeBreaksFromBreaksWarningCount = 0

var isPromptToRememberHabitShowedInLastHabit = false///   reason:-Make sure it doesn't happen twice in a row though.


var arrAllCustomRoutine = [routine]()
struct routine {
    var title:String
    var sequenceId:String
    var startTime:Time?
    var endTime:Time?
    var nextSheduledTime: Date?// for postpone// and whenever routine is start at sheduled time we will remove sheduled time
    var triggerOnDemand:Bool
    var arrAllHabits = [habit]()// all habits in settings
    //    var arrAllHabitsPreFilter = [habit]()// all habits but removed which was done in another pc and which index is greater then current index // current index is 0 but user has done 4rth in another pc so remove that one just to show to user
    var arrAllFilteredHabits = [habit]()// user selected habits to choose
    var skipForDate:Date?
    var days_of_week:[String]
    var lastCompletedSequence:Date?
}


var arrAllDaysMorningHabits = [habit]()
var arrAllDaysEveningHabits = [habit]()

var arrPreFilteredMorningHabits = [habit]()
var arrPreFilteredEveningHabits = [habit]()

var arrFilteredMorningHabits = [habit]()
var arrFilteredEveningHabits = [habit]()
var isLastActivityStoppedInRunningState = false// only use ful in morning habit evening habit
var lastActivityRunningId = ""// only use ful in morning habit evening habit
var lastActivityStoppedTimerCount = 0
struct habit {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var urlsArray:[String]
    var logQuantity:Bool!
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var allowedFocusMode:String!
    var activity_sequence_id:String!
    var run_micro_breaks:Bool!
    var take_notes:String!
    var isPriorityHigh:Bool!
    var days_of_week:[String]!
    var text_instructions = ""
    var imgUrls = [String]()
    var completion_requirements = ""
    var useTimer:Bool = true
    var logQuantityQuestions = [quantityQuestion]()
    var checkList = [String]()
    var tutorial:String!
    var showSavedDistractingWebsites = false
    var cutOffTime:Time?
    init(id:String, name:String, durationSeconds:Int, urlsArray:[String], logQuantity:Bool, logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],allowedFocusMode:String, activity_sequence_id:String, run_micro_breaks:Bool, take_notes:String,isPriorityHigh:Bool,days_of_week:[String], text_instructions:String, imgUrls:[String], completion_requirements:String, useTimer:Bool, checkList:[String], tutorial:String) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.allowedFocusMode = allowedFocusMode
        self.activity_sequence_id = activity_sequence_id
        self.run_micro_breaks = run_micro_breaks
        self.take_notes = take_notes
        self.isPriorityHigh = isPriorityHigh
        self.days_of_week = days_of_week
        self.text_instructions = text_instructions
        self.imgUrls = imgUrls
        self.completion_requirements = completion_requirements
        self.useTimer = useTimer
        self.checkList = checkList
        self.tutorial = tutorial
    }
}

var isHighPrioritySequenceGoing = false


var introActivity:habit?

var activityAllowedFocusApps = [String]()
var activityAllowedFocusUrls = [String]()


let NO_NOTE = "NO_NOTE"
let DURING_ACTIVITY = "DURING_ACTIVITY"
let END_OF_ACTIVITY = "END_OF_ACTIVITY"


enum CHOICETYPE:Int{
    case _NONE_ = 11, _COMPETENCY_, _RANDOM_, _CHECKLIST_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
}

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


struct quantityQuestion{
    var id:String!
    var minValue:Int!
    var maxValue:Int!
    var question:String!
    var logQuantityType:String!
    var quantity:Double = 0
    var minValueDescription:String!
    var maxValueDescription:String!
    init(id:String, minValue:Int, maxValue:Int, question:String, logQuantityType:String, minValueDescription:String, maxValueDescription:String) {
        self.id = id
        self.minValue = minValue
        self.maxValue = maxValue
        self.question = question
        self.logQuantityType = logQuantityType
        self.minValueDescription = minValueDescription
        self.maxValueDescription = maxValueDescription
    }
}
struct activityChoice {
    var id:String!
    var name:String!
    var urlsArray:[String]
    var logQuantityQuestion:String!
    var logQuantity:Bool!
    var logQuantityType:String!
    var logQuantityQuestions = [quantityQuestion]()
    init(name:String, urlsArray:[String], logQuantityQuestion:String, logQuantity:Bool, logQuantityType:String, id:String) {
        self.id = id
        self.name = name
        self.urlsArray = urlsArray
        self.logQuantityQuestion = logQuantityQuestion
        self.logQuantity = logQuantity
        self.logQuantityType = logQuantityType
    }
}


var currentRoutineIndex = 0
func startCustomRoutine(index:Int, isOnDemand:Bool){
    currentRoutineIndex = index
    if isFocusModeOnOrPaused(){//53fd08d9-90f6-41db-b920-aa1fd017146e, 3dd1f268-96f4-492c-b098-89dea60a013a
        addLog(text: "isFocusModeOnOrPaused True: focusModeFinished.")
        appdelegate!.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:true)
        return;
    }
    
    addLog(text: "Initiating Custom routine habits.")
    arrAllCustomRoutine[index].nextSheduledTime = nil
    
    currentState = ._CUSTOM_ROUTINE_
    appdelegate!.checkTrialExpire()
    currentHabitIndex = -1
    habitTotalCompletedSeconds = 0
    additionalHabitTotalCompletedSeconds = 0
    
    if appdelegate!.isUserOnMeeting{
        addLog(text: "isUserOnMeeting True: Morning Habits skipped for some time.")
    }
    
    if arrAllCustomRoutine.count != 0 {
        //        if need to get last saved habits then we need to comment line below
        //        arrAllCustomRoutine[index].arrAllFilteredHabits = arrAllCustomRoutine[index].arrAllHabits
        appdelegate!.abortAllProcess()
        mainWindowControllerObj?.showWindow(appdelegate)
        showBlankWindowInSecondaryMonitor()
        mainViewControllerObj!.showRoutineAllHabits(routineIndex: index)
    }
    
    mainViewControllerObj?.showLoaderView()

    
    allApiObject.getLastActivityInfo(completionHandler: { json in
        DispatchQueue.main.async {
            
            mainViewControllerObj?.hideLoaderView()
            if currentState != ._CUSTOM_ROUTINE_{
                return;
            }
            var morningStartDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            
            if Date().compare(morningStartDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
                morningStartDate = Calendar.current.date(byAdding: .day, value: -1, to: morningStartDate) ?? morningStartDate
            }
            print(json)
            //            if isMainWindowLoaded{// if main window is visible show loader
            //                if mainWindowControllerObj?.window?.isVisible ?? false{
            //                    mainViewControllerObj?.removeSubViews()
            //                }
            //            }
            if json != nil{

                if let current_activity_assigned_at = json?.value(forKey: "current_activity_assigned_at") as? String{
                    if let activityAssignedDate = getDateFromStringInUtc(date: current_activity_assigned_at, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                        if let currentActivitySequence = json?.value(forKey: "current_activity_sequence") as? NSDictionary{
                            
                            if let currentActivity = json?.value(forKey: "current_activity") as? NSDictionary{
                                if let sequenceId = currentActivitySequence.value(forKey: "id") as? String, let activityId = currentActivity.value(forKey: "id") as? String{
                                    
                                    
                                    
                                    let habitSequenceID = arrAllCustomRoutine[currentRoutineIndex].sequenceId
                                    
                                    
                                    
                                    if activityAssignedDate.compare(morningStartDate) == .orderedDescending{//if activityAssignedDate > startDate
                                        // morning activity start hui thi lekin puri nahi hui hai
                                        if habitSequenceID == sequenceId{
                                            //                print("current_activity_sequence is pending")
                                            addLog(text: "custom habit sequnce is pending. start from current pending habit")
                                            //                                                self.isProcessingHabitRoutine = false
                                            var skippedActivities = [String]()
                                            if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
                                                skippedActivities = activities
                                            }//current_sequence_completed_activities
                                            
                                            var completedActivities = [String]()
                                            if let activities = json?.value(forKey: "current_sequence_completed_activities") as? [String]{
                                                completedActivities = activities
                                            }
                                            //                                                self.startHabitsCall(activityId: activityId, skippedActivities:skippedActivities, completedActivities: completedActivities)
                                            
                                            startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: activityId, skippedActivities:skippedActivities, completedActivities: completedActivities)
                                            
                                        }else{//it means current activity is not from current sequence
                                            
                                            startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                                            
                                        }
                                    }
                                    else{
                                        //                print("pending routin is not from current day clean all running sequence")
                                        addLog(text: "pending routin is not from current day clean all running sequence")
                                        //                                            forceCompleteCurrentSequence no need
                                        
                                        startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                                    }
                                    
                                    
                                }else{
                                    addLog(text: "start new routine sequence:- current sequence Id or current activity Id not found")
                                    startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                                }
                            }else{
                                addLog(text: "start new routine sequence:- current_activity not found as dictionary")// ktyaa krna chahiye yha
                                
                                startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                            }
                        }else{
                            addLog(text: "start new routine sequence:- current_activity_sequence not found as dictionary")
                            startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                        }
                    }else{
                        addLog(text: "start new routine sequence:- can't create Date object from current_activity_assigned_at")
                        startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                    }
                }else{
                    addLog(text: "start new routine sequence :- current_activity_assigned_at not found :- \(json!)")
                    
                    startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
                }
            }else{
                addLog(text: "func backgrounThread:- Last Activity Info is nil, search is there any habit done info found in local userdefauts")
                // check local
                startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:[], completedActivities: [])
            }
        }
    }
    )
    
}


func checkCustomRoutineTime(){
    // will not excute during morning routine and shutoff time
    
    if isPurchased == false && daysLeft <= 0{//
        // will not execute custom rouine if app if subscription is active
        return;
    }
    
    if currentState != ._MORNING_HABIT_ && currentState != ._CUSTOM_ROUTINE_ && currentState != ._EVENING_HABIT_ && !appdelegate!.isProcessingHabitRoutine && !isProcessingCustomRoutine{
        for i in 0..<arrAllCustomRoutine.count{

            if !arrAllCustomRoutine[i].triggerOnDemand{

                if let skipDate = arrAllCustomRoutine[i].skipForDate{
                    if Calendar.current.isDateInToday(skipDate){
                        continue;
                    }
                }
                
                let currentDate = Date()
                var startDate = currentDate
                var endDate = currentDate
                
                let startTimeRoutine = arrAllCustomRoutine[i].startTime
                let endTimeRoutine = arrAllCustomRoutine[i].endTime
                let nextSheduledTimeRoutine = arrAllCustomRoutine[i].nextSheduledTime
                

                if startTimeRoutine != nil{
                    startDate = Calendar.current.date(bySettingHour: startTimeRoutine!.hour, minute: startTimeRoutine!.minute, second: startTimeRoutine!.second, of: currentDate)!// start time objectfrom start time var
                    endDate = Calendar.current.date(bySettingHour: endTimeRoutine!.hour, minute: endTimeRoutine!.minute, second: endTimeRoutine!.second, of: currentDate)!// end time objectfrom from end time var
                    if let lastCompletedSequence = arrAllCustomRoutine[i].lastCompletedSequence{
                        if lastCompletedSequence.compare(startDate) == .orderedDescending{
                            continue;
                        }
                    }
                }
                
                // check is current routine is allowd for today or not
                 
                let currentWeekDay = Date().dayOfWeek()
                var isAllowedCurrentRoutine = false
                
                if arrAllCustomRoutine[i].days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                    isAllowedCurrentRoutine = true
                }else if arrAllCustomRoutine[i].days_of_week.contains(where: {$0.compare("weekdays", options: .caseInsensitive) == .orderedSame}) {
                    if !currentWeekDay.localizedCaseInsensitiveContains("sat") && !currentWeekDay.localizedCaseInsensitiveContains("sat"){
                        isAllowedCurrentRoutine = true
                    }
                }else if arrAllCustomRoutine[i].days_of_week.contains(where: {$0.compare("weekend", options: .caseInsensitive) == .orderedSame}) {
                    if currentWeekDay.localizedCaseInsensitiveContains("sat") || currentWeekDay.localizedCaseInsensitiveContains("sat"){
                        isAllowedCurrentRoutine = true
                    }
                }else if arrAllCustomRoutine[i].days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                    isAllowedCurrentRoutine = true
                }
                 
                 
                if !isAllowedCurrentRoutine{
                    continue;
                }
                
                
                var isRoutineTime = false
                
                if endDate.compare(startDate) == .orderedDescending{// end date is greater then start date. normal case
                    if currentDate.compare(endDate) == .orderedAscending  && currentDate.compare(startDate) == .orderedDescending{
                        isRoutineTime = true
                    }
                    
                }else if currentDate.compare(endDate) == .orderedAscending  || currentDate.compare(startDate) == .orderedDescending{// startdate is 10 pm and end date is 2 am // end date is lower then start date
                    isRoutineTime = true
                }
                
                
                
                if let nextSheduledTimeRoutine = nextSheduledTimeRoutine{ // is postpone state
                    if isRoutineTime{
                        let startDate = nextSheduledTimeRoutine.addingTimeInterval(-5)
                        let endDate = nextSheduledTimeRoutine.addingTimeInterval(10)
                        
                        
                        isRoutineTime = false
                        if endDate.compare(startDate) == .orderedDescending{// end date is greater then start date. normal case
                            if currentDate.compare(endDate) == .orderedAscending  && currentDate.compare(startDate) == .orderedDescending{
                                isRoutineTime = true
                            }
                            
                        }else if currentDate.compare(endDate) == .orderedAscending  || currentDate.compare(startDate) == .orderedDescending{
                            isRoutineTime = true// end date is lower then start date
                        }
                        
                    }else{
                        arrAllCustomRoutine[i].nextSheduledTime = nil// if no routine time then make it nil. beacuse this is not useful now. its time has gone now reset it
                    }
                }
                
                
                
                if isRoutineTime{
                    arrAllCustomRoutine[i].nextSheduledTime = nil
                    isCustomRoutineWasRunningInPostponeMorningHabit = false
                    isCustomRoutineWasRunningInPostponeEveningHabit = false
                    if currentState == ._POSTPON_MORNING_HABIT_{
                        isCustomRoutineWasRunningInPostponeMorningHabit = true
                    }
                    
                    currentRoutineIndex = i
                    isProcessingCustomRoutine = true
                    

                    allApiObject.getLastActivityInfo(completionHandler: { json in
                        DispatchQueue.main.async {
//                            var morningStartDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
//                            
//                            if Date().compare(morningStartDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
//                                morningStartDate = Calendar.current.date(byAdding: .day, value: -1, to: morningStartDate) ?? morningStartDate
//                            }
                            print(json)
                            if json != nil{
                                
                                if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                                    if let customRoutines = todayRoutineProgress.value(forKey: "custom_routines") as? [NSDictionary]{
                                        let sequenceID = arrAllCustomRoutine[currentRoutineIndex].sequenceId
                                        for routine in customRoutines {
                                            if let todaySequenceId = routine.value(forKey: "sequence_id") as? String, let status = routine.value(forKey: "status") as? String{
                                                if todaySequenceId == sequenceID{
                                                    if status.lowercased() == "completed"{
                                                        isProcessingCustomRoutine = false
                                                        arrAllCustomRoutine[i].lastCompletedSequence = Date()
                                                        return;
                                                    }
                                                }
                                            }
                                        }
                                        
                                    }
                                }
                                if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                                    if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                        let sequenceID = arrAllCustomRoutine[currentRoutineIndex].sequenceId
                                        if lastCompletedSequenceId == sequenceID{
                                            if let lastCompletedSequenceStartedAt = json?.value(forKey: "last_completed_sequence_started_at") as? String{
                                                if let activityStartDate = getDateFromStringInUtc(date: lastCompletedSequenceStartedAt, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                                    
                                                    if activityStartDate.compare(startDate) == .orderedDescending{ // custom routine done already
                                                        isProcessingCustomRoutine = false
                                                        arrAllCustomRoutine[i].lastCompletedSequence = Date()
                                                        return;
                                                    }
                                                    
                                                }
                                            }
                                            
                                            
                                        }
                                        
                                    }
                                }
                            }
                            currentState = ._CUSTOM_ROUTINE_
                            isProcessingCustomRoutine = false
                            showCustomRoutineTimeWindow(index: currentRoutineIndex)
                        }
                    })
                    break;
                }else{
                    // if no routine time and nextSheduledTimeRoutine is passed then make it nil. beacuse this is not useful now. its time has gone now reset it
                    
                    if let nextSheduledTime = arrAllCustomRoutine[i].nextSheduledTime{
                        if currentDate.compare(nextSheduledTime) == .orderedDescending{//>
                            arrAllCustomRoutine[i].nextSheduledTime = nil
                        }
                    }
                }
            }

        }
    }
}

//skipped activities will always there in completed activities
func startCustomRoutmieHabitsCall(routineIndex:Int, activityId:String?, skippedActivities:[String], completedActivities:[String]){
    addLog(text: "Initiating Custom Routmie habits.")
    additionalHabitTotalCompletedSeconds = 0
    habitTotalCompletedSeconds = 0
    //    if isUserOnMeeting{ // 
    //        addLog(text: "isUserOnMeeting True: Morning Habits skipped for some time.")
    //        return
    //    }
    appdelegate!.abortAllProcess()
    if activityId == nil{
        
        
        mainWindowControllerObj?.showWindow(appdelegate)
        showBlankWindowInSecondaryMonitor()
        mainViewControllerObj!.startDirectIncompleteCustomRoutineHabitAtIndex(index: 0, isLastActivitySkipped:false)
    }else{
        // let arrTempFilteredMorningHabits = arrAllCustomRoutine[routineIndex].arrAllFilteredHabits
        //  arrFilteredMorningHabits.removeAll()
        
        var isActivityFound = false
        //            for i in 0..<arrTempFilteredMorningHabits.count{
        //
        //                if arrTempFilteredMorningHabits[i].id == activityId!{
        //                    arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
        //                    isActivityFound = true
        //                }else if isActivityFound{
        //                    if !completedActivities.contains(arrTempFilteredMorningHabits[i].id){
        //                        arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
        //                    }else{
        //                        if !skippedActivities.contains(arrTempFilteredMorningHabits[i].id){
        //                            if arrTempFilteredMorningHabits[i].useTimer{
        //                                additionalHabitTotalCompletedSeconds += arrTempFilteredMorningHabits[i].durationSeconds
        //                            }
        //                        }
        //                    }
        //                }else{
        //                    arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
        //                }
        //
        //            }
        
        for id in skippedActivities{
            for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id == id{
                    let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i]
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: i)
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: 0)
                }
                
            }
        }
        
        for id in completedActivities{
            for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id == id{
                    let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i]
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: i)
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: 0)
                }
                
            }
        }
        
        
        
        //            arrPreFilteredMorningHabits = arrFilteredMorningHabits
        //  //Let user temporarily customise routine before starting#938
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        //            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
        //                if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
        //                    if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && date.compare(startDate) == .orderedDescending{
        //                        if arrHabitIds.count != 0{
        //                            arrFilteredMorningHabits.removeAll()
        //                            var isActivityFound = false
        //                            for habit in arrPreFilteredMorningHabits{
        //                                if habit.id == activityId!{
        //                                    if arrHabitIds.contains(habit.id){
        //                                        arrFilteredMorningHabits.append(habit)
        //                                    }
        //                                    isActivityFound = true
        //                                }else if isActivityFound{
        //                                    if arrHabitIds.contains(habit.id){
        //                                        arrFilteredMorningHabits.append(habit)
        //                                    }
        //                                }else{
        //                                    arrFilteredMorningHabits.append(habit)
        //                                }
        //                            }
        //                            if arrFilteredMorningHabits.count == 0{
        //                                arrFilteredMorningHabits = arrPreFilteredMorningHabits
        //                            }
        //                        }else{
        //                            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
        //                        }
        //                    }
        //                }
        //            }
        //
        
        
        additionalHabitTotalCompletedSeconds = 0
        mainWindowControllerObj?.showWindow(appdelegate!)
        showBlankWindowInSecondaryMonitor()
        isActivityFound = false
        let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
        for i in 0..<arrHabits.count{
            if arrHabits[i].id == activityId!{
                isActivityFound = true
                if i == 0{
                    mainViewControllerObj!.startDirectIncompleteCustomRoutineHabitAtIndex(index: i, isLastActivitySkipped:false)
                }else {
                    if skippedActivities.count == 0{
                        habitTotalCompletedSeconds = 0
                        for j in 0..<i{
                            if arrHabits[j].useTimer{
                                habitTotalCompletedSeconds += arrHabits[j].durationSeconds!
                            }
                        }
                        mainViewControllerObj!.startDirectIncompleteCustomRoutineHabitAtIndex(index: i, isLastActivitySkipped:false)
                    }else{
                        var isLastActivitySkipped = false
                        if let lastActivityId = arrHabits[i-1].id{
                            if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                isLastActivitySkipped = true
                            }
                            
                            habitTotalCompletedSeconds = 0
                            for j in 0..<i{
                                let habit = arrHabits[j]
                                if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                    //skiped
                                }else{
                                    if habit.useTimer{
                                        habitTotalCompletedSeconds += habit.durationSeconds!
                                    }
                                    //completed
                                }
                                
                            }
                        }
                        mainViewControllerObj!.startDirectIncompleteCustomRoutineHabitAtIndex(index: i, isLastActivitySkipped:isLastActivitySkipped)
                        
                    }
                    
                }
                break;
            }
        }
        if !isActivityFound{
            addLog(text: "func startCustomRoutmieHabitsCall:- current activity id from actiity props not found in habit list.")
            
            //******************************************************************//
            //Doing this because if current habit id is not in selected habits list then we will found next habit to do according to selected list and if we can't find any current habit then show all habits
            var lastActivityFoundIndex = -1
            var isLastActivitySkipped = false
            for i in 0..<arrHabits.count{
                if completedActivities.contains(arrHabits[i].id){
                    lastActivityFoundIndex = i+1// start next habit
                    if skippedActivities.contains(arrHabits[i].id){
                        isLastActivitySkipped = true
                    }else{
                        isLastActivitySkipped = false
                    }
                }
            }
            if lastActivityFoundIndex == -1{
                //                    mainViewControllerObj!.showal //  no need to do any thing
            }else{
                mainViewControllerObj!.startDirectIncompleteCustomRoutineHabitAtIndex(index: lastActivityFoundIndex, isLastActivitySkipped:isLastActivitySkipped)
            }
            
        }
        
    }
}


func settingsChangedDuringHabitsCurrentActivityProps(){
    addLog(text: "Settings Changed")
    appdelegate!.abortAllProcess()
    mainWindowControllerObj?.window?.close()
    hideBlankWindowInSecondaryMonitor()
    currentState = ._NOTHING_
    let alert = NSAlert()
    alert.setSharingType()
    var settingsChangedText = "It looks like your settings have been updated. App will restart to take effect."//
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        settingsChangedText = common.value(forKey: "settingsChangedText") as? String ?? settingsChangedText
    }
    alert.messageText = settingsChangedText
    alert.addButton(withTitle: buttonOkText)
    NSApplication.shared.activate(ignoringOtherApps: true)
    alert.runModal()
    
    appdelegate!.quitAndRestartApp()
    print("settings changed")
}


/*
 {
     "completing_focus_block" = "<null>";
     "current_activity" = "<null>";
     "current_activity_assigned_at" = "<null>";
     "current_activity_sequence" = "<null>";
     "current_focus_mode" = "<null>";
     "current_focus_mode_finish_time" = "<null>";
     "current_sequence_completed_activities" =     (
     );
     "current_sequence_skipped_activities" = "<null>";
     "last_completed_sequence" =     {
         "activity_ids" =         (
             "2cbd1dce-a2c9-487c-bda7-a5813000fa80",
             "03ddc55c-620f-447a-9642-2948f43fbcbf"
         );
         "created_at" = "2025-03-27T07:13:49.033Z";
         "custom_routine" =         {
             "created_at" = "2024-12-09T14:08:11.310Z";
             "days_of_week" =             (
                 MON,
                 TUE,
                 WED,
                 THU
             );
             "end_time" = "13:00";
             id = "adfea68a-e3d7-488a-83ba-bfceefc46e62";
             name = "Lunch Time";
             "start_time" = "12:00";
             trigger = "ON_SCHEDULE";
             "updated_at" = "2024-12-09T14:08:11.310Z";
         };
         "generated_sequence_activity_ids" = "<null>";
         "generated_total_duration_seconds" = "<null>";
         id = "53fd08d9-90f6-41db-b920-aa1fd017146e";
         "pack_id" = "<null>";
         "total_duration_seconds" = 122;
         type = standalone;
         "updated_at" = "2025-03-27T07:13:49.033Z";
         "user_id" = "69d0f00a-e68f-4871-a8b5-0d057967e32a";
     };
     "last_completed_sequence_at" = "2025-04-03T11:31:30.311Z";
     "last_completed_sequence_started_at" = "2025-04-03T11:30:25.036Z";
     "last_time_user_settings_modified" = "2025-04-02T13:32:20.369Z";
 }
 
 {
     "completing_focus_block" = "<null>";
     "current_activity" = "<null>";
     "current_activity_assigned_at" = "<null>";
     "current_activity_sequence" = "<null>";
     "current_focus_mode" = "<null>";
     "current_focus_mode_finish_time" = "<null>";
     "current_sequence_completed_activities" =     (
     );
     "current_sequence_skipped_activities" = "<null>";
     "last_completed_sequence" =     {
         "activity_ids" =         (
             "78b736f7-025c-4a6b-a9d0-910d6533705a",
             "82bbc997-1668-4b18-9b29-24c2a49cd073",
             "6b7dd0d9-4b9c-4087-b266-5d7a1224b026"
         );
         "created_at" = "2025-03-27T07:13:49.033Z";
         "custom_routine" =         {
             "created_at" = "2024-12-09T14:08:11.310Z";
             "days_of_week" =             (
                 MON,
                 TUE,
                 WED,
                 THU
             );
             "end_time" = "13:00";
             id = "adfea68a-e3d7-488a-83ba-bfceefc46e62";
             name = "Lunch Time";
             "start_time" = "12:00";
             trigger = "ON_SCHEDULE";
             "updated_at" = "2024-12-09T14:08:11.310Z";
         };
         "generated_sequence_activity_ids" = "<null>";
         "generated_total_duration_seconds" = "<null>";
         id = "3dd1f268-96f4-492c-b098-89dea60a013a";
         "pack_id" = "<null>";
         "total_duration_seconds" = 243;
         type = standalone;
         "updated_at" = "2025-03-27T07:13:49.033Z";
         "user_id" = "69d0f00a-e68f-4871-a8b5-0d057967e32a";
     };
     "last_completed_sequence_at" = "2025-04-03T11:43:34.631Z";
     "last_completed_sequence_started_at" = "2025-04-03T11:38:18.205Z";
     "last_time_user_settings_modified" = "2025-04-02T13:32:20.369Z";
 })
 
 */

/*
 "today_routine_progress" =     {
     "custom_routines" =         (
                     {
             "sequence_id" = "68b3b720-8cf9-49d9-88bc-a0b8e4de7349";
             status = completed;
         }
     );
     "evening_routine" = "<null>";
     "morning_routine" =         {
         "sequence_id" = "974374ad-e3cb-4e06-9038-dbb1023a4b15";
         status = completed;
     };
     "standalone_routines" =         (
     );
 };
 */
