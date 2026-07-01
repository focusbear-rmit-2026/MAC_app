//
//  routine.swift
//  FocusBear
//
//  Created by Manish Jain on 28/03/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var isCustomRoutineWasRunningInPostponeMorningHabit = false
var isCustomRoutineWasRunningInPostponeEveningHabit = false

var isCustomRoutineWasRunningBetweenMorningHabit = false
var isCustomRoutineWasRunningBetweenEveningHabit = false

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
/// #1590: counts consecutive break postpones via the hold control, to escalate the
/// required hold time (5s → 10s → 15s). Reset when a break is actually taken. Kept
/// separate from activityPostponeCount (which habits also increment) so the hold
/// always starts at 5s for a fresh break.
var breakPostponeHoldCount = 0
var activitySkipCount = 0
var isHabitsDisabled = false
var isHabitAlreadyShowed = true
var lastActivityPerformedTime:Date?
var postponeBreaksFromBreaksWarningCount = 0

var isPromptToRememberHabitShowedInLastHabit = false///   reason:-Make sure it doesn't happen twice in a row though.

var eveningRoutineLastPostponeTime:Date?
var focusSummaryLastPostponeTime:Date?


var arrAllCustomRoutine = [routine]() { didSet { requestDayPlanRefresh() } }
struct routine {
    var title:String
    var sequenceId:String
    var startTime:Time?
    var endTime:Time?
    var nextSheduledTime: Date?// for postpone// and whenever routine is start at sheduled time we will remove sheduled time
    var triggerOnDemand:Bool
    var arrAllHabits = [habit]()// all habits in settings
    var arrAllPreFilterHabits = [habit]()
    var arrAllFilteredHabits = [habit]()// user selected habits to choose
    var skipForDate:Date?
    var days_of_week:[String]
    var lastCompletedSequence:Date?
}


var arrAllDaysMorningHabits = [habit]()
var arrAllDaysEveningHabits = [habit]()

var arrPreFilteredMorningHabits = [habit]()
var arrPreFilteredEveningHabits = [habit]()

/// Coalesced Day Plan refresh. arrFiltered{Morning,Evening}Habits and arrAllCustomRoutine are mutated
/// from many paths (the server progress filtering that runs on launch, skip/done, the resort loop), and
/// the Day Plan reads those same arrays. Their didSet re-renders the Day Plan so it always matches the
/// habit table by construction — debounced to the next runloop tick so a burst of mutations triggers a
/// single refresh instead of one per element.
var dayPlanRefreshPending = false
func requestDayPlanRefresh() {
    if dayPlanRefreshPending { return }
    dayPlanRefreshPending = true
    DispatchQueue.main.async {
        dayPlanRefreshPending = false
        firstViewControllerObj?.refreshScheduleIfVisible()
    }
}

var arrFilteredMorningHabits = [habit]() { didSet { requestDayPlanRefresh() } }
var arrFilteredEveningHabits = [habit]() { didSet { requestDayPlanRefresh() } }
var isLastActivityStoppedInRunningState = false// only use ful in morning habit evening habit
var lastActivityRunningId = ""// only use ful in morning habit evening habit
var lastActivityStoppedTimerCount = 0
struct habit {
    var id:String!
    var name:String!
    var nameWithoutIcon:String = ""
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
    var fakeIdForDevice:String = ""
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

    /// True for "allowed activity" habits — ones that intentionally let you use other apps / sites
    /// during them (an allowed-apps habit, an allowed-websites habit, or an allowed focus mode).
    /// These get the Habit Player | Day Plan tabs and a postpone-free minimise.
    var isAllowedActivityHabit: Bool {
        (allowApps?.count ?? 0) > 0
            || (allowUrls?.count ?? 0) > 0
            || !((allowedFocusMode ?? "").isEmpty)
    }
}

var isHighPrioritySequenceGoing = false

/// True while the habit currently being played is an "allowed activity" habit (see
/// habit.isAllowedActivityHabit). Set in timerViewcontroller.startTimerHabit and used by the window
/// close/minimise logic so these habits — which run in the background — minimise without the postpone
/// prompt. Covers allow-URLs habits too, where currentHabitPlaying is nil.
var isAllowedActivityHabitPlaying = false

/// Robust "is an allowed-activity habit currently running" check used by the close/minimise paths.
/// The per-habit flag above is the primary signal, but it isn't set if the habit was started on a
/// prior build/session; the focus-mode + currentHabitPlaying/currentRelaxHabitPlaying signals are the
/// safety net so minimise/close reliably backgrounds the window instead of prompting to postpone.
var isAllowedActivityHabitCurrentlyRunning: Bool {
    isAllowedActivityHabitPlaying
        || isAnyAllowedFocusModeActivityRunning
        || (currentHabitPlaying?.isAllowedActivityHabit ?? false)
        || (currentRelaxHabitPlaying?.isAllowedActivityHabit ?? false)
}


var introActivity:habit?

var activityAllowedFocusApps = [String]()
var activityAllowedFocusUrls = [String]()


let NO_NOTE = "NO_NOTE"
let DURING_ACTIVITY = "DURING_ACTIVITY"
let END_OF_ACTIVITY = "END_OF_ACTIVITY"


enum CHOICETYPE:Int{
    case _NONE_ = 11, _COMPETENCY_, _RANDOM_, _CHECKLIST_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
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
    isCustomRoutineWasRunningBetweenMorningHabit = false
    isCustomRoutineWasRunningBetweenEveningHabit = false
    if currentState == ._POSTPONE_MORNING_HABIT_{
        isCustomRoutineWasRunningInPostponeMorningHabit = true
        isCustomRoutineWasRunningInPostponeEveningHabit = false
    }else if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
        isCustomRoutineWasRunningInPostponeEveningHabit = true
        isCustomRoutineWasRunningInPostponeMorningHabit = false
    }else if currentState != ._CUSTOM_ROUTINE_{
        isCustomRoutineWasRunningInPostponeMorningHabit = false
        isCustomRoutineWasRunningInPostponeEveningHabit = false
    }
    
    currentRoutineIndex = index
    if isFocusModeOnOrPaused(){//53fd08d9-90f6-41db-b920-aa1fd017146e, 3dd1f268-96f4-492c-b098-89dea60a013a
        addLog(text: "isFocusModeOnOrPaused True: focusModeFinished.")
        leftMenuVcObj?.customRoutineStarted()// added here v 2.28.452. reason Bug: When starting a custom routine, the app does not switch to the Custom Routine tab. Because of this mismatch, several issues occur—for example, the window does not close. The reason is that the app remains in the custom routine state, but the custom routine view is not visible.
        appdelegate!.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:true, shouldUpdateFocusButton: true)
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
    
    arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllHabits
    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllHabits
    if arrAllCustomRoutine.count != 0 {
        //        if need to get last saved habits then we need to comment line below
        appdelegate!.abortAllProcess()
        mainWindowControllerObj?.showWindow(appdelegate)
        showBlankWindowInSecondaryMonitor()
        leftMenuVcObj?.showCustomRoutineView()
        getHabitsVcObject().showRoutineAllHabits(routineIndex: index)
    }
    
    getHabitsVcObject().showLoaderView()
    leftMenuVcObj?.customRoutineStarted()
    
    
    allApiObject.getLastActivityInfo(completionHandler: { json in
        DispatchQueue.main.async {
            
            getHabitsVcObject().hideLoaderView()
            if currentState != ._CUSTOM_ROUTINE_{
                return;
            }
            var morningStartDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            
            if Date().compare(morningStartDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
                morningStartDate = Calendar.current.date(byAdding: .day, value: -1, to: morningStartDate) ?? morningStartDate
            }

            if json != nil{

                if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                    if let customRoutines = todayRoutineProgress.value(forKey: "custom_routines") as? [NSDictionary]{
                        let sequenceID = arrAllCustomRoutine[currentRoutineIndex].sequenceId
                        for routine in customRoutines {
                            if let todaySequenceId = routine.value(forKey: "sequence_id") as? String, let status = routine.value(forKey: "status") as? String{
                                if todaySequenceId == sequenceID{
                                    let statusLowerCased = status.lowercased()
                                    if (status.lowercased() == "in_progress" || status.lowercased() == "postponed"){
                                        
                                        addLog(text: "custom habit sequnce is pending. start from current pending habit")
                                        //                                                self.isProcessingHabitRoutine = false
                                        var skippedActivities = [String]()
                                        if let activities = routine.value(forKey: "skipped_habit_ids") as? [String]{
                                            skippedActivities = activities
                                        }//current_sequence_completed_activities
                                        
                                        var completedActivities = [String]()
                                        if let activities = routine.value(forKey: "completed_habit_ids") as? [String]{
                                            completedActivities = activities
                                        }
                                        //                                                self.startHabitsCall(activityId: activityId, skippedActivities:skippedActivities, completedActivities: completedActivities)
                                        
                                        startCustomRoutmieHabitsCall(routineIndex:currentRoutineIndex, activityId: nil, skippedActivities:skippedActivities, completedActivities: completedActivities, needToCreateActivityId: true)
                                        
                                        return;
                                    }
                                }
                            }
                        }
                        
                    }
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
        // will execute custom rouine if app subscription is active
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
                    if currentState == ._POSTPONE_MORNING_HABIT_{
                        isCustomRoutineWasRunningInPostponeMorningHabit = true
                        isCustomRoutineWasRunningInPostponeEveningHabit = false
                    }else if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
                        isCustomRoutineWasRunningInPostponeEveningHabit = true
                        isCustomRoutineWasRunningInPostponeMorningHabit = false
                    }else{
                        isCustomRoutineWasRunningInPostponeMorningHabit = false
                        isCustomRoutineWasRunningInPostponeEveningHabit = false
                    }
                    
                    currentRoutineIndex = i
                    isProcessingCustomRoutine = true
                    

                    allApiObject.getLastActivityInfo(completionHandler: { json in
                        DispatchQueue.main.async {
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

func getListCustomRoutineTime()->[routine]{
    var arrCustomRoutineTimeHabit = [routine]()
    if isPurchased == false && daysLeft <= 0{//
        // will  execute custom rouine if app subscription is active
        return [];
    }
    
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
                arrCustomRoutineTimeHabit.append(arrAllCustomRoutine[i])
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
    return arrCustomRoutineTimeHabit
}


func isCustomRoutineTime(id:String, completion: @escaping (Bool,Int,Int) -> Void){
    if isProcessingCustomRoutine {
        completion(false, 0, 0)
        return;
    }
    let list = getListCustomRoutineTime()
    if list.count == 0{
        completion(false, 0, 0)
        return;
    }
    var isRoutineFound = false
    for routine in list{
        if routine.sequenceId == id{
            
            for i in 0..<arrAllCustomRoutine.count{
                if arrAllCustomRoutine[i].sequenceId == id{
                    isRoutineFound = true
                    currentRoutineIndex = i
                    isProcessingCustomRoutine = true
                    
                    allApiObject.getLastActivityInfo(completionHandler: { json in
                        DispatchQueue.main.async {
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
                                                        completion(false, 0, 0)
                                                        return;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            isProcessingCustomRoutine = false
                            var totalSecondsRoutine = 0
                            for habit in arrAllCustomRoutine[i].arrAllHabits{
                                if habit.useTimer{
                                    totalSecondsRoutine += habit.durationSeconds
                                }else{
                                    totalSecondsRoutine += 5 * 60
                                }
                                
                            }
                            
                            
                            completion(true, currentRoutineIndex, totalSecondsRoutine)
                            return;
                        }
                    })
                    break;
                }
            }
            break
        }
    }
    if !isRoutineFound{
        completion(false, 0, 0)
        return;
    }
}




//skipped activities will always there in completed activities
func startCustomRoutmieHabitsCall(routineIndex:Int, activityId:String?, skippedActivities:[String], completedActivities:[String], needToCreateActivityId:Bool = false){
    addLog(text: "Initiating Custom Routmie habits.")
    additionalHabitTotalCompletedSeconds = 0
    habitTotalCompletedSeconds = 0
    appdelegate!.abortAllProcess()
    var activityId = activityId
    
    var needToCreateActivityId = needToCreateActivityId
    
    if completedActivities.count == 0 && skippedActivities.count == 0{
        needToCreateActivityId = false
    }
    arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllHabits
    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllHabits
    if activityId == nil && !needToCreateActivityId{
        mainWindowControllerObj?.showWindow(appdelegate)
        showBlankWindowInSecondaryMonitor()
        leftMenuVcObj?.showCustomRoutineView()
        getHabitsVcObject().startDirectIncompleteCustomRoutineHabitAtIndex(index: 0, isLastActivitySkipped:false)
    }else{
        
        var isActivityFound = false
        
        for id in skippedActivities{
            for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id == id{
                    let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i]
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: i)
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: 0)
                    break;
                }
                
            }
        }
        
        for id in completedActivities{
            for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id == id{
                    let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i]
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: i)
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: 0)
                    break;
                }
                
            }
        }
        
        if needToCreateActivityId && activityId == nil{
            if skippedActivities.count != 0 || completedActivities.count != 0{
                
                var isActivityFound = false
                for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                    if !completedActivities.contains(arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id){
                        activityId = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id
                        isActivityFound = true
                    }
                    if isActivityFound{
                        break;
                    }
                }
            }
        }
        
        //  //Let user temporarily customise routine before starting#938
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        additionalHabitTotalCompletedSeconds = 0
        mainWindowControllerObj?.showWindow(appdelegate!)
        showBlankWindowInSecondaryMonitor()
        leftMenuVcObj?.showCustomRoutineView()
        isActivityFound = false
        let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
        for i in 0..<arrHabits.count{
            if arrHabits[i].id == activityId!{
                isActivityFound = true
                if i == 0{
                    getHabitsVcObject().startDirectIncompleteCustomRoutineHabitAtIndex(index: i, isLastActivitySkipped:false)
                }else {
                    if skippedActivities.count == 0{
                        habitTotalCompletedSeconds = 0
                        for j in 0..<i{
                            if arrHabits[j].useTimer{
                                habitTotalCompletedSeconds += arrHabits[j].durationSeconds!
                            }
                        }
                        getHabitsVcObject().startDirectIncompleteCustomRoutineHabitAtIndex(index: i, isLastActivitySkipped:false)
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
                        getHabitsVcObject().startDirectIncompleteCustomRoutineHabitAtIndex(index: i, isLastActivitySkipped:isLastActivitySkipped)
                        
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
                //                    getHabitsVcObject().showal //  no need to do any thing
            }else{
                getHabitsVcObject().startDirectIncompleteCustomRoutineHabitAtIndex(index: lastActivityFoundIndex, isLastActivitySkipped:isLastActivitySkipped)
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
    var settingsChangedText = "It looks like your settings have been updated. App will restart to take effect."//
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        settingsChangedText = common.value(forKey: "settingsChangedText") as? String ?? settingsChangedText
    }

    NSApplication.shared.activate(ignoringOtherApps: true)
    showCustomAlert(title: settingsChangedText, body: nil, buttonOkText: buttonOkText, buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl:nil, buttonLinkText: nil, completionHandler: {isOkClicked in
        print(isOkClicked)
        appdelegate!.quitAndRestartApp()
    })
}



var kUserdefaultsHabitsDurationDoneToday = "kUserdefaultsHabitsDurationDoneToday"

func saveCurrentHabitCurrentDurationDone(id:String, duration:Int){
    var allHabitsCurrentDurationData = [String:[String:Any]]()
    if let oldData = UserDefaults.standard.object(forKey: kUserdefaultsHabitsDurationDoneToday) as? [String:[String:Any]]{
        allHabitsCurrentDurationData = oldData
    }
    allHabitsCurrentDurationData[id] = ["date": Date(), "duration":duration]
    
    UserDefaults.standard.set(allHabitsCurrentDurationData, forKey: kUserdefaultsHabitsDurationDoneToday)
}


func getCurrentHabitCurrentDurationDone(id:String)->Int?{
    var allHabitsCurrentDurationData = [String:[String:Any]]()
    if let oldData = UserDefaults.standard.object(forKey: kUserdefaultsHabitsDurationDoneToday) as? [String:[String:Any]]{
        allHabitsCurrentDurationData = oldData
    }

    if let currentHabitData = allHabitsCurrentDurationData[id]{
        if let habitDate = currentHabitData["date"] as? Date, let duration = currentHabitData["duration"] as? Int{
            if currentState == ._MORNING_HABIT_{
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                if habitDate.compare(startDate) == .orderedDescending{
                    return duration
                }
            }else if currentState == ._EVENING_HABIT_{
                var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                if Date().compare(shutOffdate) == .orderedAscending{// iska matlab 20-24 k bich
                    shutOffdate = Calendar.current.date(byAdding: .day, value: -1, to: shutOffdate) ?? shutOffdate
                }
                if habitDate.compare(shutOffdate) == .orderedDescending{
                    return duration
                }
            }
        }
    }
    return nil
}


func getNextRoutineInfo()->(Date, String, Bool){
    var nextRoutineTime:Date = Date()
    var nextRoutineIsEveningRoutine = true
    var nextRoutineName = "Evening Routine"
    if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
        nextRoutineName = habitsStateVcInfo.value(forKey: "titleEveningRoutine") as? String ?? nextRoutineName
    }
    var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    let calendar = Calendar.current
    // Get today's 11:59 PM
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 23
    components.minute = 59
    components.second = 59
    let elevenFiftyNinePM = calendar.date(from: components) ?? Date()
    
    if shutOffdate > elevenFiftyNinePM{//>
        shutOffdate = Calendar.current.date(byAdding: .day, value: 1, to: shutOffdate) ?? shutOffdate
    }
    nextRoutineTime = shutOffdate


    for i in 0..<arrAllCustomRoutine.count{

        if !arrAllCustomRoutine[i].triggerOnDemand{

            if let skipDate = arrAllCustomRoutine[i].skipForDate{
                if Calendar.current.isDateInToday(skipDate){
                    continue;
                }
            }
            
            let currentDate = Date()
            var startDate = currentDate

            let startTimeRoutine = arrAllCustomRoutine[i].startTime
            let endTimeRoutine = arrAllCustomRoutine[i].endTime
            let nextSheduledTimeRoutine = arrAllCustomRoutine[i].nextSheduledTime
            

            if startTimeRoutine != nil{
                startDate = Calendar.current.date(bySettingHour: startTimeRoutine!.hour, minute: startTimeRoutine!.minute, second: startTimeRoutine!.second, of: currentDate)!// start time objectfrom start time var
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
            
            if let nextSheduledTimeRoutine = nextSheduledTimeRoutine{ // is postpone state
                if nextSheduledTimeRoutine < nextRoutineTime{
                    nextRoutineTime = nextSheduledTimeRoutine
                    nextRoutineName = arrAllCustomRoutine[i].title
                    nextRoutineIsEveningRoutine = false
                }
            }else{
                if startDate < nextRoutineTime{
                    nextRoutineTime = startDate
                    nextRoutineName = arrAllCustomRoutine[i].title
                    nextRoutineIsEveningRoutine = false
                }
            }
        }

    }

    return (nextRoutineTime, nextRoutineName, nextRoutineIsEveningRoutine)
}

func isShutOffTimeGoing()->Bool{
    if startTime == nil || shutOffTime == nil{
        return false
    }
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    let currentDate = Date()
    
    var isShutOffTime = false
    
    if  startDate.compare(shutOffdate) == .orderedDescending{//(start date jyada ho shut off date se ) ex shut off 5 bje start date 8 bje
        if currentDate.compare(startDate) == .orderedAscending  && currentDate.compare(shutOffdate) == .orderedDescending{
            isShutOffTime = true
        }
        
    }else if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
        isShutOffTime = true
    }
    return isShutOffTime
}


func isCutOffTimeGoing()->Bool{
    if startTime == nil || cutOffTime == nil{
        return false
    }
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
    let currentDate = Date()
    
    var isCutOffTime = false
    
    if  startDate.compare(cutOffDate) == .orderedDescending{
        if currentDate.compare(startDate) == .orderedAscending  && currentDate.compare(cutOffDate) == .orderedDescending{
            isCutOffTime = true
        }
        
    }else if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(cutOffDate) == .orderedDescending{
        isCutOffTime = true
    }
    
    return isCutOffTime
    
}


func isCutOffTimeAboutToReach() -> Bool {
    if startTime == nil || cutOffTime == nil{
        return false
    }
    let now = Date()
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
    let currentDate = Date()
    
    if  startDate.compare(cutOffDate) == .orderedDescending{
        if currentDate.compare(startDate) == .orderedAscending  && currentDate.compare(cutOffDate) == .orderedDescending{
            return true
        }
        
    }else if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(cutOffDate) == .orderedDescending{
        return true
    }
    
    let differenceInSeconds = cutOffDate.timeIntervalSince(now)
    let differenceInMinutes = differenceInSeconds / 60
    
    // Return true if 10 minutes or less remain, but cutoff time is still in the future
    return differenceInMinutes > 0 && differenceInMinutes <= 10
}




func restorePostponeStateIfNeeded() {
    guard
        let endDate = UserDefaults.standard.object(
            forKey: kUserDefaultsLastRoutinePostponeEndDate
        ) as? Date
    else { return }
    
    guard
        let state = UserDefaults.standard.object(
            forKey: kUserDefaultsLastRoutinePostponeState
        ) as? Int
    else { return }
    let remaining = endDate.timeIntervalSinceNow

    if remaining > 0 {
        // ⏳ Still postponed
        let remainingSeconds = Int(remaining)
        if state == CURRENTSTATE._POSTPONE_MORNING_HABIT_.rawValue{
            addLog(text: "Restored morning postpone: \(remainingSeconds)s left")
            getHabitsVcObject().postponeMorningHabitFor(minutes: remainingSeconds / 60, secondsToPostpone: remainingSeconds, showAskFocusModeView: false, showAskIntention: false, isExtendingPostponeFromAppStart: true)

        }else if state == CURRENTSTATE._POSTPONE_EVENING_HABIT_.rawValue{
            addLog(text: "Restored evening postpone: \(remainingSeconds)s left")
            if isShutOffTimeGoing(){
                getHabitsVcObject().postponeEveningHabitFor(minutes: remainingSeconds / 60, secondsToPostpone: remainingSeconds, showAskFocusModeView: false, showAskIntention: false, isExtendingPostponeFromAppStart: true)
            }else{
                UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
                UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
            }
        }else if state == CURRENTSTATE._POSTPONE_FOCUS_SUMMARY_.rawValue{
            addLog(text: "Restored focus summary postpone: \(remainingSeconds)s left")
            if !(focusSummaryVcObj?.isViewLoaded ?? false){
                focusSummaryVcObj?.loadView()
                focusSummaryVcObj?.viewVisibleCount = 1
            }
            
            getHabitsVcObject().postponeFocusSummaryFor(minutes: remainingSeconds / 60, showAskIntention: false)
        }
 
    } else {
        // ❌ Postpone expired while app was closed
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
    }
}
