//
//  routinePostponedInfoVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 23/05/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class routinePostponedInfoVc: NSViewController {
    @IBOutlet weak var btnStartFirstHabit: Button!
    @IBOutlet weak var tblViewHabits: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var actionBarItemPlay = "Play"
    var actionBarItemDone = "Done"
    var actionBarItemSkip = "Skip"

    var lCurrentState:CURRENTSTATE = ._NOTHING_
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = ""
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            actionBarItemPlay = activityInfo.value(forKey: "actionBarItemPlay") as? String ?? actionBarItemPlay
            actionBarItemDone = activityInfo.value(forKey: "actionBarItemDone") as? String ?? actionBarItemDone
            actionBarItemSkip = activityInfo.value(forKey: "actionBarItemSkip") as? String ?? actionBarItemSkip
        }

        // Schedule view: adds the "Schedule | Habits" tab over this postponed habit screen.
        setupScheduleTab()
    }
    
    
    override func viewWillAppear() {

        currentHabitIndex = -1
        var sourceHabits: [habit] = []
        
        if lCurrentState == ._MORNING_HABIT_{
            sourceHabits = arrAllDaysMorningHabits
            lblTitle.stringValue = "Morning routine postponed. Begin a habit to resume the morning routine."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                lblTitle.stringValue = activityInfo.value(forKey: "titleMorningRoutinePostponed") as? String ?? lblTitle.stringValue
            }
        }else if lCurrentState == ._EVENING_HABIT_{
            sourceHabits = arrAllDaysEveningHabits
            lblTitle.stringValue = "Evening routine postponed. Begin a habit to resume the evening routine."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                lblTitle.stringValue = activityInfo.value(forKey: "titleEveningRoutinePostponed") as? String ?? lblTitle.stringValue
            }
        }
        
        if let arrIds = UserDefaults.standard.object(
            forKey: kUserdefaultsLastHabitsIdsBeforePostpone
        ) as? [String] {

            let habits = sourceHabits.filter {
                arrIds.contains($0.id)
            }

            if lCurrentState == ._MORNING_HABIT_ {
                arrFilteredMorningHabits = habits
            } else {
                arrFilteredEveningHabits = habits
            }
        }

        if let arrIds = UserDefaults.standard.object(
            forKey: kUserdefaultsPrefilterLastHabitsIdsBeforePostpone
        ) as? [String] {

            let habits = sourceHabits.filter {
                arrIds.contains($0.id)
            }

            if lCurrentState == ._MORNING_HABIT_ {
                arrPreFilteredMorningHabits = habits
            } else {
                arrPreFilteredEveningHabits = habits
            }
        }
    }
    
    override func viewDidAppear() {
        tblViewHabits.reloadData()
        // viewWillAppear re-shows the habit list; re-hide it behind the Day Plan so its occluded
        // cells can't fire hover/clicks (stray hand cursor / starting the selected habit).
        updateScheduleTabForState()

        if lCurrentState == ._MORNING_HABIT_{
            getMorningHabitsListAgain()
            //focusButtonService-------//
            focusButtonServiceObject.sendMorningHabitsToFocusDevice()
            //---------//
        }else if lCurrentState == ._EVENING_HABIT_{
            getEveningHabitsListAgain()
            //focusButtonService-------//
            focusButtonServiceObject.sendEveningHabitsToFocusDevice()
            //---------//
        }
    }
    
    func getMorningHabitsListAgain(){
        if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
            return;
        }
        mainViewControllerObj?.showLoaderView()
        allApiObject.getLastActivityInfo(completionHandler: { json in
            DispatchQueue.main.async {
                mainViewControllerObj?.hideLoaderView()
                if json != nil{
                    
                    
                    arrFilteredMorningHabits.removeAll()
                    arrPreFilteredMorningHabits.removeAll()
                    let currentWeekDay = Date().dayOfWeek()
                    
                    for habit in arrAllDaysMorningHabits{
                        if habit.days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                            arrFilteredMorningHabits.append(habit)
                        }else if habit.days_of_week.contains(where: {$0.compare("weekdays", options: .caseInsensitive) == .orderedSame}) {
                            if !currentWeekDay.localizedCaseInsensitiveContains("sat") && !currentWeekDay.localizedCaseInsensitiveContains("sat"){
                                arrFilteredMorningHabits.append(habit)
                            }
                        }else if habit.days_of_week.contains(where: {$0.compare("weekend", options: .caseInsensitive) == .orderedSame}) {
                            if currentWeekDay.localizedCaseInsensitiveContains("sat") || currentWeekDay.localizedCaseInsensitiveContains("sat"){
                                arrFilteredMorningHabits.append(habit)
                            }
                        }else if habit.days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                            arrFilteredMorningHabits.append(habit)
                        }
                    }
                    
                    isActivitiesReducedInExpiredApp = false
                    if isExpired{
                        if arrFilteredMorningHabits.count > activitiesCountInExpireApp{
                            isActivitiesReducedInExpiredApp = true
                            let arrTempFilteredMorningHabits = arrFilteredMorningHabits
                            arrFilteredMorningHabits.removeAll()
                            for i in 0..<activitiesCountInExpireApp{
                                arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                            }
                        }
                    }
                    
                    // new work  26/4/25 / cehck from "today_routine_progress" in app version 1.22.362
                    
                    if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                        if let morningRoutine = todayRoutineProgress.value(forKey: "morning_routine") as? NSDictionary,let sequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
                            if let todaySequenceId = morningRoutine.value(forKey: "sequence_id") as? String, let status = morningRoutine.value(forKey: "status") as? String{
                                let statusLowerCased = status.lowercased()
                                if todaySequenceId == sequenceID && (statusLowerCased == "in_progress" || statusLowerCased == "postponed"){
                                    
                                    var skippedActivities = [String]()
                                    if let activities = morningRoutine.value(forKey: "skipped_habit_ids") as? [String]{
                                        skippedActivities = activities
                                    }//current_sequence_completed_activities
                                    
                                    var completedActivities = [String]()
                                    if let activities = morningRoutine.value(forKey: "completed_habit_ids") as? [String]{
                                        completedActivities = activities
                                    }
                                    
                                    
                                    let arrTempFilteredMorningHabits = arrFilteredMorningHabits
                                    arrFilteredMorningHabits.removeAll()
                                    
                                    for i in 0..<arrTempFilteredMorningHabits.count{
                                        
                                        if !completedActivities.contains(arrTempFilteredMorningHabits[i].id){
                                            arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                                        }else{
                                            if !skippedActivities.contains(arrTempFilteredMorningHabits[i].id){
                                                if arrTempFilteredMorningHabits[i].useTimer{
                                                    additionalHabitTotalCompletedSeconds += arrTempFilteredMorningHabits[i].durationSeconds
                                                }
                                            }
                                        }
                                        
                                    }
                                    
                                    arrPreFilteredMorningHabits = arrFilteredMorningHabits
                                    
                                    //temporarily customise routine
                                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                    if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                                        if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                                            if lastSavedSequenceId == arrFilteredMorningHabits.first?.activity_sequence_id && date.compare(startDate) == .orderedDescending{
                                                if arrHabitIds.count != 0{
                                                    arrFilteredMorningHabits.removeAll()
                                                    for habit in arrPreFilteredMorningHabits{
                                                        if arrHabitIds.contains(habit.id){
                                                            arrFilteredMorningHabits.append(habit)
                                                        }
                                                    }
                                                    if arrFilteredMorningHabits.count == 0{
                                                        arrFilteredMorningHabits = arrPreFilteredMorningHabits
                                                    }
                                                }else{
                                                    UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                    self.tblViewHabits.reloadData()
                    //focusButtonService-------//
                    focusButtonServiceObject.sendMorningHabitsToFocusDevice()
                    //---------//
                }
            }
        })
    }
             
    func getEveningHabitsListAgain(){
        if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
            return;
        }
        mainViewControllerObj?.showLoaderView()
        allApiObject.getLastActivityInfo(completionHandler: { json in
            DispatchQueue.main.async {
                mainViewControllerObj?.hideLoaderView()
                if json != nil{
                    
                    
                    arrFilteredEveningHabits.removeAll()
                    arrPreFilteredEveningHabits.removeAll()
                    
                    let currentWeekDay = Date().dayOfWeek()
                    let isCutOffTimeGoing = isCutOffTimeGoing()
                    for habit in arrAllDaysEveningHabits{
                        
                        if isCutOffTimeGoing{
                            if habit.isPriorityHigh{
                                if let cutOffTime = habit.cutOffTime{
                                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                    let currentDate = Date()
                                    if currentDate > cutOffDate{
                                        addLog(text: "evening habit skipped:- running late cutoff time passed for this habit:- \(habit.name)  \(habit.id)") // remove this
                                        continue;
                                    }
                                }
                            }else{
                                addLog(text: "evening habit skipped:- Global cutoffTime passed and this habit is not high priority habit:- \(habit.name)  \(habit.id)")
                                continue
                            }
                        }
                        
                        if habit.days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                            arrFilteredEveningHabits.append(habit)
                        }else if habit.days_of_week.contains(where: {$0.compare("weekdays", options: .caseInsensitive) == .orderedSame}) {
                            if !currentWeekDay.localizedCaseInsensitiveContains("sat"){
                                arrFilteredEveningHabits.append(habit)
                            }else{
                                addLog(text: "evening habit skipped:- current day is not from weekdays:- \(habit.name)  \(habit.id)") // remove this
                            }
                        }else if habit.days_of_week.contains(where: {$0.compare("weekend", options: .caseInsensitive) == .orderedSame}) {
                            if currentWeekDay.localizedCaseInsensitiveContains("sat"){
                                arrFilteredEveningHabits.append(habit)
                            }else{
                                addLog(text: "evening habit skipped:- current day is not from weekend:- \(habit.name)  \(habit.id)") // remove this
                            }
                        }else if habit.days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                            arrFilteredEveningHabits.append(habit)
                        }else{
                            addLog(text: "evening habit skipped:- current day is not from selected days \(habit.days_of_week):- \(habit.name)  \(habit.id)") // remove this
                        }
                    }
                    
                    
                    isActivitiesReducedInExpiredApp = false
                    if isExpired{
                        if arrFilteredEveningHabits.count > activitiesCountInExpireApp{
                            isActivitiesReducedInExpiredApp = true
                            let arrTempFilteredEveningHabits = arrFilteredEveningHabits
                            arrFilteredEveningHabits.removeAll()
                            
                            for i in 0..<arrTempFilteredEveningHabits.count{
                                if arrTempFilteredEveningHabits[i].showSavedDistractingWebsites{
                                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                                }
                            }
                            
                            for i in 0..<activitiesCountInExpireApp{
                                arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                            }
                        }
                    }
                    
                    // new work  26/4/25 / cehck from "today_routine_progress" in app version 1.22.362
                    
                    if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                        if let eveningRoutine = todayRoutineProgress.value(forKey: "evening_routine") as? NSDictionary,let sequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
                            if let todaySequenceId = eveningRoutine.value(forKey: "sequence_id") as? String, let status = eveningRoutine.value(forKey: "status") as? String{
                                let statusLowerCased = status.lowercased()
                                if todaySequenceId == sequenceID && (statusLowerCased == "in_progress" || statusLowerCased == "postponed"){
                                    
                                    var skippedActivities = [String]()
                                    if let activities = eveningRoutine.value(forKey: "skipped_habit_ids") as? [String]{
                                        skippedActivities = activities
                                    }//current_sequence_completed_activities
                                    
                                    var completedActivities = [String]()
                                    if let activities = eveningRoutine.value(forKey: "completed_habit_ids") as? [String]{
                                        completedActivities = activities
                                    }
                                    
                                    
                                    let arrTempFilteredEveningHabits = arrFilteredEveningHabits
                                    arrFilteredEveningHabits.removeAll()
                                    
                                    for i in 0..<arrTempFilteredEveningHabits.count{
                                        
                                        if !completedActivities.contains(arrTempFilteredEveningHabits[i].id){
                                            arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                                        }else{
                                            if !skippedActivities.contains(arrTempFilteredEveningHabits[i].id){
                                                if arrTempFilteredEveningHabits[i].useTimer{
                                                    additionalHabitTotalCompletedSeconds += arrTempFilteredEveningHabits[i].durationSeconds
                                                }
                                            }
                                        }
                                        
                                    }
                                    
                                    arrPreFilteredEveningHabits = arrFilteredEveningHabits
                                    
                                    //temporarily customise routine
                                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                    if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                                        if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                                            if lastSavedSequenceId == arrPreFilteredEveningHabits.first?.activity_sequence_id && date.compare(startDate) == .orderedDescending{
                                                if arrHabitIds.count != 0{
                                                    arrFilteredEveningHabits.removeAll()
                                                    for habit in arrPreFilteredEveningHabits{
                                                        if arrHabitIds.contains(habit.id){
                                                            arrFilteredEveningHabits.append(habit)
                                                        }
                                                    }
                                                    if arrFilteredEveningHabits.count == 0{
                                                        arrFilteredEveningHabits = arrPreFilteredEveningHabits
                                                    }
                                                }else{
                                                    UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                    self.tblViewHabits.reloadData()
                    //focusButtonService-------//
                    focusButtonServiceObject.sendEveningHabitsToFocusDevice()
                    //---------//
                }
            }
        })
    }
    
    // MARK: - all helper functions
    func morningHabitAlreadyDoneClicked(){
        addLog(text: "routinePostponedInfoVc action bar:- morningHabitAlreadyDoneClicked")
        isAnyAllowedFocusModeActivityWasRunningInLastActivity = false
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex]
        if arrFilteredMorningHabits[currentHabitIndex].useTimer{
            habitTotalCompletedSeconds += lastHabit.durationSeconds!
        }
        lastActivityPerformedTime = Date()
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredMorningHabits[lastHabitIndex])
        
        
        arrFilteredMorningHabits.remove(at: currentHabitIndex) // dont remove if last index
        if let index = arrPreFilteredMorningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
            arrPreFilteredMorningHabits.remove(at: index)
        }
        tblViewHabits.reloadData()
        //focusButtonService-------//
        focusButtonServiceObject.sendMorningHabitsToFocusDevice()
        //---------//
        if arrFilteredMorningHabits.count == 0{
            if currentState == ._POSTPONE_MORNING_HABIT_{
                currentState = ._NOTHING_
                getHabitsVcObject().stopPostponeEndTimer()
            }
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
            
            // clear all  postpone info so that when app started again it will not postpone routine again
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
            
            isHabitAlreadyShowed = true
            habitsVcObj?.showHabitState()
        }
        
        if lastHabit.logQuantity{
            
            getHabitsVcObject().showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            logQuantityVcObj?.resetData(name: lastHabit.name, durationInSeconds: "\(duration)", logQuantityQuestion: lastHabit.logQuantityQuestion, currentState: lCurrentState, logQuantityType: "", activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, take_notes: lastHabit.take_notes, notes: "", logQuantityQuestions: lastHabit.logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "morning routine", activity: lastHabit.name, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            if lastHabit.take_notes == END_OF_ACTIVITY{
                getHabitsVcObject().showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else{
                allApiObject.activityCompletedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
        }
        getHabitsVcObject().saveRemainingHabitIdForPostponedRoutineList(state: ._MORNING_HABIT_)
    }
    
    func eveningHabitAlreadyDoneClicked(){
        addLog(text: "action bar:- eveningHabitAlreadyDoneClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex]
        if arrFilteredEveningHabits[currentHabitIndex].useTimer{
            habitTotalCompletedSeconds += lastHabit.durationSeconds!
        }
        lastActivityPerformedTime = Date()
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredEveningHabits[lastHabitIndex])
        
        
        arrFilteredEveningHabits.remove(at: currentHabitIndex)
        if let index = arrPreFilteredEveningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
            arrPreFilteredEveningHabits.remove(at: index)
        }
        tblViewHabits.reloadData()
        //focusButtonService-------//
        focusButtonServiceObject.sendEveningHabitsToFocusDevice()
        //---------//
        if arrFilteredEveningHabits.count == 0{
            if currentState == ._POSTPONE_EVENING_HABIT_{
                currentState = ._NOTHING_
                getHabitsVcObject().stopPostponeEndTimer()
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
            }
            isHabitAlreadyShowed = false
            UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
            
            // clear all  postpone info so that when app started again it will not postpone routine again
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
            
            
            UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
            currentHabitIndex = -1
            habitsVcObj?.showHabitState()
        }
        
        if lastHabit.logQuantity{
            
            getHabitsVcObject().showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            logQuantityVcObj?.resetData(name: lastHabit.name, durationInSeconds: "\(duration)", logQuantityQuestion: lastHabit.logQuantityQuestion, currentState: lCurrentState, logQuantityType: "", activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, take_notes: lastHabit.take_notes, notes: "", logQuantityQuestions: lastHabit.logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "evening routine", activity: lastHabit.name, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            if lastHabit.take_notes == END_OF_ACTIVITY{
                getHabitsVcObject().showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else{
                allApiObject.activityCompletedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
        }
        getHabitsVcObject().saveRemainingHabitIdForPostponedRoutineList(state: ._EVENING_HABIT_)
    }

    func tryMorningRoutineSkip(){
        if SettingsManagerObject.isEasySkipEnabled{
            self.morningHabitSkipClicked()
        }else{
            mainViewControllerObj!.showOneClickSkipHabitView(completionHandler: {
                self.morningHabitSkipClicked()
            })
        }
    }
    
    func tryEveningRoutineSkip(){
        if SettingsManagerObject.isEasySkipEnabled{
            self.eveningHabitSkipClicked()
        }else{
            mainViewControllerObj!.showOneClickSkipHabitView(completionHandler: {
                self.eveningHabitSkipClicked()
            })
        }
    }
    
    func morningHabitSkipClicked(){
        addLog(text: "routinePostponedInfoVc action bar:- morningHabitSkipClicked")
        if currentHabitIndex == -1 || currentHabitIndex >= arrFilteredMorningHabits.count{
            addLog(text: "Invalid index. skip cancelled")
            return;
        }
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex]
        lastActivityPerformedTime = Date()
        
        arrFilteredMorningHabits.remove(at: currentHabitIndex) // dont remove if last index
        if let index = arrPreFilteredMorningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
            arrPreFilteredMorningHabits.remove(at: index)
        }
        tblViewHabits.reloadData()
        //focusButtonService-------//
        focusButtonServiceObject.sendMorningHabitsToFocusDevice()
        //---------//
        if arrFilteredMorningHabits.count == 0{
            if currentState == ._POSTPONE_MORNING_HABIT_{
                currentState = ._NOTHING_
                getHabitsVcObject().stopPostponeEndTimer()
            }
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
            
            // clear all  postpone info so that when app started again it will not postpone routine again
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
            
            isHabitAlreadyShowed = true
            habitsVcObj?.showHabitState()
        }
        
        allApiObject.activitySkippedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, completionHandler: {dic in
            
        })
    }
    
    func eveningHabitSkipClicked(){
        addLog(text: "routinePostponedInfoVc action bar:- eveningHabitSkipClicked")
        if currentHabitIndex == -1 || currentHabitIndex >= arrFilteredEveningHabits.count{
            addLog(text: "Invalid index. skip cancelled")
            return;
        }
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex]
        lastActivityPerformedTime = Date()
        
        arrFilteredEveningHabits.remove(at: currentHabitIndex) // dont remove if last index
        if let index = arrPreFilteredEveningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
            arrPreFilteredEveningHabits.remove(at: index)
        }
        tblViewHabits.reloadData()
        //focusButtonService-------//
        focusButtonServiceObject.sendEveningHabitsToFocusDevice()
        //---------//
        if arrFilteredEveningHabits.count == 0{
            if currentState == ._POSTPONE_EVENING_HABIT_{
                currentState = ._NOTHING_
                getHabitsVcObject().stopPostponeEndTimer()
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
            }
            isHabitAlreadyShowed = false
            UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
            
            // clear all  postpone info so that when app started again it will not postpone routine again
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
            
            
            UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
            currentHabitIndex = -1
            habitsVcObj?.showHabitState()
        }
        
        allApiObject.activitySkippedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, completionHandler: {dic in
            
        })
    }

    func sortMorningHabitsBySelectedFirst(){
        if tblViewHabits.selectedRow != 0 && tblViewHabits.selectedRow != -1{
            var tempArr = arrFilteredMorningHabits
            arrFilteredMorningHabits.removeAll()
            arrFilteredMorningHabits.append(tempArr[tblViewHabits.selectedRow])
            tempArr.remove(at: tblViewHabits.selectedRow)
            for item in tempArr{
                arrFilteredMorningHabits.append(item)
            }
        }
    }
    
    func sortEveningHabitsBySelectedFirst(){
        if tblViewHabits.selectedRow != 0 && tblViewHabits.selectedRow != -1{
            var tempArr = arrFilteredEveningHabits
            arrFilteredEveningHabits.removeAll()
            arrFilteredEveningHabits.append(tempArr[tblViewHabits.selectedRow])
            tempArr.remove(at: tblViewHabits.selectedRow)
            for item in tempArr{
                arrFilteredEveningHabits.append(item)
            }
        }
    }
    
    func playSelectedHabit(){
        addLog(text: "routinePostponedInfoVc playSelectedHabit")
        if lCurrentState == ._MORNING_HABIT_{
            sortMorningHabitsBySelectedFirst()
            currentHabitIndex = -1
            getHabitsVcObject().startFirstMorningHabit()
        }else if lCurrentState == ._EVENING_HABIT_{
            sortEveningHabitsBySelectedFirst()
            
            if isCutOffTimeGoing(){
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].isPriorityHigh{
                        
                        if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                            let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                            let currentDate = Date()
                            if currentDate > cutOffDate{
                                addLog(text: "routinePostponedInfoVc func btnPlayClicked")// remove this
                                addLog(text: "routinePostponedInfoVc evening habit skipped:- this first habit is high priority habit but cutoff time of this habit has passed:- \(arrFilteredEveningHabits[i].name)  \(arrFilteredEveningHabits[i].id)") // remove this
                                continue;
                            }
                        }
                        
                        currentHabitIndex = i - 1
                        break;
                    }
                }
            }else{
                currentHabitIndex = -1
            }

            getHabitsVcObject().startFirstEveningHabit()
        }
    }
    
    
    // MARK: - all actions
    
    @objc func btnDoneClicked(sender: NSButton){
        addLog(text: "[user-action] routinePostponedInfoVc action bar:- btnDoneClicked")
        currentHabitIndex = sender.tag
        if lCurrentState == ._MORNING_HABIT_{
            if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipMorning{
                mainViewControllerObj?.showPasswordView()

                enterPasswordVcObj?.requestAuthorization(
                    action: {
                        self.morningHabitAlreadyDoneClicked()
                    },
                    onCancel: {
                        print("User cancelled password entry")
                    }
                )
            }else{
                morningHabitAlreadyDoneClicked()
            }
        }else if lCurrentState == ._EVENING_HABIT_{
            if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipEvening{
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.requestAuthorization(
                    action: {
                        self.eveningHabitAlreadyDoneClicked()
                    },
                    onCancel: {
                        print("User cancelled password entry")
                    }
                )
            }else{
                eveningHabitAlreadyDoneClicked()
            }
        }
    }
    
    @objc func btnSkipClicked(sender: NSButton){
        addLog(text: "[user-action] action bar:- btnSkipClicked")
        currentHabitIndex = sender.tag
        if lCurrentState == ._MORNING_HABIT_{
            if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipMorning{
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.requestAuthorization(
                    action: {
                        self.tryMorningRoutineSkip()
                    },
                    onCancel: {
                        print("User cancelled password entry")
                    }
                )
            }else{
                tryMorningRoutineSkip()
            }
        }else if lCurrentState == ._EVENING_HABIT_{
            if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipEvening{
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.requestAuthorization(
                    action: {
                        self.tryEveningRoutineSkip()
                    },
                    onCancel: {
                        print("User cancelled password entry")
                    }
                )
            }else{
                tryEveningRoutineSkip()
            }
        }
    }
    
    @objc func btnPlayClicked(sender: NSButton){
        addLog(text: "[user-action] routinePostponedInfoVc action bar:- btnPlayClicked")
        playSelectedHabit()
    }
    
    @IBAction func btnStartFirstHabitClicked(_ sender: Any) {
        addLog(text: "[user-action] routinePostponedInfoVc action bar:- btnSkipClicked")
        playSelectedHabit()
    }
}

extension routinePostponedInfoVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if lCurrentState == ._MORNING_HABIT_{
            return  arrFilteredMorningHabits.count
        }else if lCurrentState == ._EVENING_HABIT_{
            return  arrFilteredEveningHabits.count
        }else{
            return 0
        }
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            cell.boxBg.fillColor = NSColor.clear
            cell.lblTitle.textColor = NSColor.labelColor
            if lCurrentState == ._MORNING_HABIT_{
                guard row < arrFilteredMorningHabits.count else {
                    return NSTableCellView()
                }
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredMorningHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.orange
                    cell.lblTitle.textColor = NSColor.white
                }
            }else if lCurrentState == ._EVENING_HABIT_{
                guard row < arrFilteredEveningHabits.count else {
                    return NSTableCellView()
                }
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredEveningHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.orange
                    cell.lblTitle.textColor = NSColor.white
                }
            }
            
            cell.boxBg.wantsLayer = true
            cell.boxBg.layer?.borderWidth = 1
            cell.boxBg.layer?.cornerRadius = 7
            
            if row == tblViewHabits.selectedRow{
                cell.boxBg.layer?.borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.blue.cgColor
                addActionBar(cell: cell, row: row)
            }else{
                cell.boxActionBar.isHidden = true
                cell.boxBg.layer?.borderColor = .clear
            }
            
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func addActionBar(cell: tblCellHabits, row:Int){
        if cell.lblTitle.tag == 99{
            cell.boxActionBar.isHidden = false
            cell.stackViewActionBar.subviews.removeAll()
            
            let itemPlay = getItemActionBarPlayVcObject()
            if !itemPlay.isViewLoaded{
                itemPlay.loadView()
            }
            itemPlay.lblTitle.stringValue = actionBarItemPlay
            itemPlay.imgView.image = NSImage(named: NSImage.touchBarPlayTemplateName)
            itemPlay.btnMain.target = self
            itemPlay.btnMain.tag = row
            itemPlay.btnMain.action = #selector(btnPlayClicked)
            itemPlay.boxBtn.fillColor = NSColor.orange
            itemPlay.imgView.contentTintColor = NSColor.white
            cell.stackViewActionBar.addView(itemPlay.view, in: .bottom)
            
            let itemDone = getItemActionBarDoneVcObject()
            if !itemDone.isViewLoaded{
                itemDone.loadView()
            }
            itemDone.lblTitle.stringValue = actionBarItemDone
            itemDone.imgView.image = NSImage(named: NSImage.menuOnStateTemplateName)
            itemDone.btnMain.target = self
            itemDone.btnMain.tag = row
            itemDone.btnMain.action = #selector(btnDoneClicked)
            cell.stackViewActionBar.addView(itemDone.view, in: .bottom)
            
            let itemSkip = getItemActionBarSkipVcObject()
            if !itemSkip.isViewLoaded{
                itemSkip.loadView()
            }
            itemSkip.lblTitle.stringValue = actionBarItemSkip
            itemSkip.imgView.image = NSImage(named: NSImage.touchBarFastForwardTemplateName)
            itemSkip.btnMain.target = self
            itemSkip.btnMain.tag = row
            itemSkip.btnMain.action = #selector(btnSkipClicked)
            cell.stackViewActionBar.addView(itemSkip.view, in: .bottom)
            
            cell.isSelected = tblViewHabits.selectedRow == row
        }else{
            cell.boxActionBar.isHidden = true
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if row != 0 && !SettingsManagerObject.isOutOfOrderHabitsAllowed{
            return false
        }
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblViewHabits.selectedRow == -1{
            return;
        }
        if lCurrentState == ._MORNING_HABIT_ || lCurrentState == ._EVENING_HABIT_{
            for row in 0..<tblViewHabits.numberOfRows{
                if let cell = tblViewHabits.view(atColumn: 0, row: row, makeIfNecessary: true) as? tblCellHabits{
                    cell.boxBg.fillColor = NSColor.clear
                    cell.lblTitle.textColor = NSColor.labelColor
                    cell.boxActionBar.isHidden = true
                    cell.isSelected = false
                    cell.boxBg.layer?.borderColor = NSColor.clear.cgColor
                }
            }
            
            if let cell = tblViewHabits.view(atColumn: 0, row: tblViewHabits.selectedRow, makeIfNecessary: true) as? tblCellHabits{
                cell.boxBg.fillColor = NSColor.orange
                cell.lblTitle.textColor = NSColor.white
                cell.isSelected = true
                cell.boxBg.layer?.borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.blue.cgColor
                addActionBar(cell: cell, row: tblViewHabits.selectedRow)
            }
        }
        
        if lCurrentState == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                let time = arrFilteredMorningHabits[tblViewHabits.selectedRow].durationSeconds ?? 0
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredMorningHabits[tblViewHabits.selectedRow].name ?? "")
            }
        }else if lCurrentState == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                let time = arrFilteredEveningHabits[tblViewHabits.selectedRow].durationSeconds ?? 0
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[tblViewHabits.selectedRow].name ?? "")
            }
        }
    }
}
