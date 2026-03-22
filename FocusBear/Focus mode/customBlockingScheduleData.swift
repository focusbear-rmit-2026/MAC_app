//
//  PauseFriction.swift
//  FocusBear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Foundation

// MARK: - Enums with API raw values
//enum PauseFriction: String, Codable {
//    case none
//    case timer
//    case hundredRandomChars = "100_random_chars"
//    case password
//}

enum State: String, Codable {
    case on
    case off
    case pause
}

// MARK: - BlockingSchedule Model
struct customBlockingSchedule: Codable, Identifiable {
    let id: String
    var name: String
    var startTime: Date   // keep as String in "HH:mm" or ISO8601 if API sends like that
    var endTime: Date
    var startTimeString: String
    var endTimeString: String
    var daysOfWeek: [Int]   // e.g. [1,2,3,4,5]
    var focusModeID: String
    //    var pauseFriction: PauseFriction
    var blockLevel: FOCUSMODESTRICTNESS
    var isAIBlockingEnabled: Bool
    var isMicroBreaksEnabled: Bool
    var state:State = .off
    var displayString: String {
        "\(daysOfWeek.formattedDays()), \(startTime.formattedTime()) to \(endTime.formattedTime())"
    }
    
    
    var blockLevelString: String {
        switch blockLevel{
            
        case ._NORMAL_:
            strictnessNormalText
        case ._STRICT_:
            strictnessStrictText
        case ._SUPER_STRICT_:
            strictnessSuperStrictText
        }
    }
    
    
//    func isBlockingActive() -> Bool {
//        let now = Date()
//        let calendar = Calendar.current
//        let weekday = calendar.component(.weekday, from: now)
//        let schedule = self
//        guard schedule.daysOfWeek.contains(weekday) else { return false }
//
//        let startDate = schedule.startTime
//        
//        var endDate = schedule.endTime
//        
//        // Handle cross-midnight
//        if endDate <= startDate {
//            endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
//        }
//        
//        return now >= startDate && now <= endDate
//    }
    
    // Assumes:
    // - schedule.daysOfWeek is [Int] using Calendar.current.component(.weekday, from:) (1 = Sunday ... 7 = Saturday)
    // - schedule.startTime and schedule.endTime are Date objects that contain the time-of-day you saved
    //   (date components will be ignored; only hour/minute/second are used)

    func isBlockingActive() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: now)

        // quick guard: if schedule not active this weekday at all
        // (we'll check yesterday separately for cross-midnight case)
        guard !daysOfWeek.isEmpty else { return false }

        // Extract time components from stored start/end times
        let startComp = calendar.dateComponents([.hour, .minute, .second], from: startTime)
        let endComp   = calendar.dateComponents([.hour, .minute, .second], from: endTime)

        // Build "today" Date objects for start and end times (using today's date)
        guard
            let todayStart = calendar.date(bySettingHour: startComp.hour ?? 0,
                                           minute: startComp.minute ?? 0,
                                           second: startComp.second ?? 0,
                                           of: now),
            let todayEnd   = calendar.date(bySettingHour: endComp.hour ?? 0,
                                           minute: endComp.minute ?? 0,
                                           second: endComp.second ?? 0,
                                           of: now)
        else {
            return false
        }

        // If the interval does NOT cross midnight (start < end on same day)
        if todayStart < todayEnd {
            // Active only if today is in schedule.daysOfWeek and now falls between start and end
            guard daysOfWeek.contains(todayWeekday) else { return false }
            return (now >= todayStart && now <= todayEnd)
        } else {
            // Interval crosses midnight (e.g., start 22:00, end 02:00)
            //
            // Two possibilities:
            // 1) The schedule started today and runs until midnight (now >= todayStart)
            //    -> only valid if today is a scheduled start-day
            if daysOfWeek.contains(todayWeekday) && now >= todayStart {
                return true
            }

            // 2) The schedule started yesterday and runs past midnight into today until todayEnd
            //    -> check yesterday's weekday is a scheduled day and now <= todayEnd
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                let yesterdayWeekday = calendar.component(.weekday, from: yesterday)
                if daysOfWeek.contains(yesterdayWeekday) && now <= todayEnd {
                    return true
                }
            }

            return false
        }
    }
    
    func remainingBlockingDuration() -> TimeInterval {
        let now = Date()
        let calendar = Calendar.current

        // Extract time components from stored start/end Dates (time-of-day only)
        let startComp = calendar.dateComponents([.hour, .minute, .second], from: startTime)
        let endComp   = calendar.dateComponents([.hour, .minute, .second], from: endTime)

        // Build a "base" start/end for any given reference day:
        func date(forDay day: Date, hour: Int?, minute: Int?, second: Int?) -> Date? {
            return calendar.date(bySettingHour: hour ?? 0,
                                  minute: minute ?? 0,
                                  second: second ?? 0,
                                  of: day)
        }

        guard
            let todayStart = date(forDay: now, hour: startComp.hour, minute: startComp.minute, second: startComp.second),
            let todayEndRaw = date(forDay: now, hour: endComp.hour, minute: endComp.minute, second: endComp.second)
        else {
            return 1
        }

        // Helper to produce an adjusted end for a given start/end on the same reference day.
        func adjustedEnd(for start: Date, rawEnd: Date) -> Date {
            // If rawEnd <= start, it means the interval crosses midnight; adjusted end should be the next day rawEnd
            if rawEnd <= start {
                return calendar.date(byAdding: .day, value: 1, to: rawEnd)!
            } else {
                return rawEnd
            }
        }

        let todayEnd = adjustedEnd(for: todayStart, rawEnd: todayEndRaw)

        // Build yesterday's start & end (the same time-of-day but on yesterday's date)
        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now),
              let yesterdayStart = date(forDay: yesterdayDate, hour: startComp.hour, minute: startComp.minute, second: startComp.second),
              let yesterdayEndRaw = date(forDay: yesterdayDate, hour: endComp.hour, minute: endComp.minute, second: endComp.second)
        else {
            return 1
        }

        let yesterdayEnd = adjustedEnd(for: yesterdayStart, rawEnd: yesterdayEndRaw)

        // If now lies in yesterday's window (schedule started yesterday and runs past midnight into today)
        if now >= yesterdayStart && now < yesterdayEnd {
            return yesterdayEnd.timeIntervalSince(now)
        }

        // If now lies in today's window (schedule starts today and runs until todayEnd or tomorrow)
        if now >= todayStart && now < todayEnd {
            return todayEnd.timeIntervalSince(now)
        }

        // Not active right now — keep the old behavior (1 second)
        return 1
    }


    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case startTime = "start_time"
        case endTime = "end_time"
        case daysOfWeek = "days_of_week"
        case focusModeID = "focus_mode_id"
        case pauseFriction = "Pause_friction"
        case blockLevel = "block_level"
        case isAIBlockingEnabled = "is_ai_blocking_enabled"
        case isMicroBreaksEnabled = "is_micro_breaks_enabled"
        case metadata = "metadata"
    }
    // Custom decoding/encoding for time strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled"
//        let days = try container.decodeIfPresent([Int].self, forKey: .daysOfWeek) ?? [0,1,2,3,4,5,6]
//        daysOfWeek = []
//        for day in days{
//            daysOfWeek.append(day + 1)
//        }
        
        // Default full week
        let defaultDays = Array(0...6)

        let decodedDays: [Int]

        if container.contains(.daysOfWeek) {
            
            // Case 1: [Int]
            if let intDays = try? container.decode([Int].self, forKey: .daysOfWeek) {
                decodedDays = intDays
            }
            // Case 2: ["all"]
            else if let stringDays = try? container.decode([String].self, forKey: .daysOfWeek),
                    stringDays.contains("all") {
                decodedDays = defaultDays
            }
            // Case 3: Wrong type / corrupted → fallback
            else {
                decodedDays = defaultDays
            }
            
        } else {
            // Case 4: Key missing → full week
            decodedDays = defaultDays
        }

        // Your +1 logic
        daysOfWeek = decodedDays.map { $0 + 1 }
        
        
        focusModeID = try container.decodeIfPresent(String.self, forKey: .focusModeID) ?? ""
        
        let blockLevelString = try container.decodeIfPresent(String.self, forKey: .blockLevel) ?? "gentle"
        switch blockLevelString {
        case "strict":        blockLevel = ._STRICT_
        case "super-strict":  blockLevel = ._SUPER_STRICT_
        case "gentle":        blockLevel = ._NORMAL_
        default:              blockLevel = ._NORMAL_
        }
        
        isAIBlockingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAIBlockingEnabled) ?? false
        isMicroBreaksEnabled = false
        
        startTimeString = try container.decodeIfPresent(String.self, forKey: .startTime) ?? "09:00"
        endTimeString = try container.decodeIfPresent(String.self, forKey: .endTime) ?? "18:00"
        
        //let start = customBlockingSchedule.parseTime(startTimeString) ?? Date()
        startTime = Self.parseTime(startTimeString) ?? Date()
        endTime = Self.parseTime(endTimeString) ?? Date()

        if startTime > endTime{
            let calendar = Calendar.current
            endTime = calendar.date(byAdding: .day, value: 1, to: endTime)!
        }
        if let metadata = try container.decodeIfPresent([String: Bool].self, forKey: .metadata) {
            isMicroBreaksEnabled = metadata["is_micro_breaks_enabled"] ?? false
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        // Shift back daysOfWeek to original form (since you added +1 while decoding)
        let encodedDays = daysOfWeek.map { $0 - 1 }
        try container.encode(encodedDays, forKey: .daysOfWeek)
        
        try container.encode(focusModeID, forKey: .focusModeID)
        
        
        // Block level → back to string
        let blockLevelString: String
        switch blockLevel {
        case ._STRICT_:        blockLevelString = "strict"
        case ._SUPER_STRICT_:  blockLevelString = "super-strict"
        case ._NORMAL_:        blockLevelString = "gentle"
        }
        try container.encode(blockLevelString, forKey: .blockLevel)
        
        try container.encode(isAIBlockingEnabled, forKey: .isAIBlockingEnabled)
       // try container.encode(isMicroBreaksEnabled, forKey: .isMicroBreaksEnabled)
        
        try container.encode(startTimeString, forKey: .startTime)
        try container.encode(endTimeString, forKey: .endTime)
        //var dic = [String:Any]()
        let metadata = ["is_micro_breaks_enabled": isMicroBreaksEnabled]
        try container.encode(metadata, forKey: .metadata)
    }
    
    // Shared formatter for "HH:mm"
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    
    static func parseTime(_ str: String) -> Date? {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formats = ["HH:mm:ss", "HH:mm"]
        for format in formats {
            timeFormatter.dateFormat = format
            if let timeDate = timeFormatter.date(from: str) {
                // Get current calendar and today's date components
                let calendar = Calendar.current
                let now = Date()
                let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)
                
                // Merge today's date with parsed time
                var combined = DateComponents()
                combined.year = todayComponents.year
                combined.month = todayComponents.month
                combined.day = todayComponents.day
                combined.hour = timeComponents.hour
                combined.minute = timeComponents.minute
                combined.second = timeComponents.second
                
                return calendar.date(from: combined)
            }
        }
        return nil
    }
    
}


extension customBlockingSchedule {
    init(
        id:String,
        name: String,
        start: String,
        end: String,
        daysOfWeek: [Int],
        focusModeID: String,
        //        pauseFriction: PauseFriction,
        blockLevel: FOCUSMODESTRICTNESS,
        isAIBlockingEnabled: Bool,
        isMicroBreaksEnabled:Bool
    ) {
        self.id = id
        self.name = name
        self.startTimeString = start
        self.endTimeString = end
        self.startTime = Self.parseTime(start) ?? Date()
        self.endTime = Self.parseTime(end) ?? Date()
        self.daysOfWeek = daysOfWeek
        self.focusModeID = focusModeID
        //        self.pauseFriction = pauseFriction
        self.blockLevel = blockLevel
        self.isAIBlockingEnabled = isAIBlockingEnabled
        self.isMicroBreaksEnabled = isMicroBreaksEnabled
    }
}





enum WeekDay: Int, Codable, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

extension Array where Element == Int {
    func formattedDays() -> String {
        let sortedDays = self.sorted()
        if sortedDays.count == 7 { return "Everyday" }
        
        var ranges: [String] = []
        var start: Int?
        var previous: Int?
        
        for day in sortedDays {
            if start == nil {
                start = day
            } else if let prev = previous, day != prev + 1 {
                // Range ended
                if start == prev {
                    ranges.append(WeekDay(rawValue: start!)!.shortName)
                } else {
                    ranges.append("\(WeekDay(rawValue: start!)!.shortName)-\(WeekDay(rawValue: prev)!.shortName)")
                }
                start = day
            }
            previous = day
        }
        
        // Add last range
        if let start = start, let prev = previous {
            if start == prev {
                ranges.append(WeekDay(rawValue: start)!.shortName)
            } else {
                ranges.append("\(WeekDay(rawValue: start)!.shortName)-\(WeekDay(rawValue: prev)!.shortName)")
            }
        }
        
        return ranges.joined(separator: ", ")
    }
}
extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}

let customBlockingScheduleManagerObj = customBlockingScheduleManager()
class customBlockingScheduleManager {// added 24/9/25 version 2.27.417
    
    var arrBlockingSchedule = [customBlockingSchedule]()
    var isAnyCustomScheduleOn = false
    var currentScheduleFinishTime:Date?
    var isAnyCustomSchedulePaused = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.dayChangedOperations(_:)), name:NSNotification.Name.NSCalendarDayChanged, object:nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func dayChangedOperations(_ aNotification: Notification) {
        addLog(text: "func call:- dayChangedOperations")
        DispatchQueue.main.async { [self] in
            dayChanged()
        }
    }
    
    func dayChanged(){
        if isAnyCustomScheduleOn || isAnyCustomSchedulePaused{
            customBlockingScheduleFinished()
        }
        for i in 0..<arrBlockingSchedule.count {
            arrBlockingSchedule[i].startTime = customBlockingSchedule.parseTime(arrBlockingSchedule[i].startTimeString) ?? arrBlockingSchedule[i].startTime
            arrBlockingSchedule[i].endTime = customBlockingSchedule.parseTime(arrBlockingSchedule[i].endTimeString) ?? arrBlockingSchedule[i].endTime
            
            if arrBlockingSchedule[i].startTime > arrBlockingSchedule[i].endTime{
                let calendar = Calendar.current
                arrBlockingSchedule[i].endTime = calendar.date(byAdding: .day, value: 1, to: arrBlockingSchedule[i].endTime)!
            }
        }
    }
    
    
    func checkCustomBlockingScheduleTime(){
        if currentState != ._MORNING_HABIT_ && currentState != ._CUSTOM_ROUTINE_ && currentState != ._EVENING_HABIT_ && !appdelegate!.isProcessingHabitRoutine && !isProcessingCustomRoutine && currentState != ._MICRO_BREAK_ && !isAnyCustomScheduleOn && !isFocusModeRunning{
            
            if let mainWindowControllerObj = mainWindowControllerObj, (mainWindowControllerObj.window?.isVisible ?? false){
                if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                    if mainViewControllerObj?.isFocusCompletedViewVisible() ?? false{
                        return;
                    }
                }
            }
            
            for i in 0..<arrBlockingSchedule.count{
                if arrBlockingSchedule[i].isBlockingActive(){
                    if validateBlockingScheduleFocusId(schedule: arrBlockingSchedule[i]){
                        if arrBlockingSchedule[i].state == .pause{
                            continue;
                        }
                        // if any another schedule paused then stop it
                        if isAnyCustomSchedulePaused{
                            isAnyCustomSchedulePaused = false
                            for i in 0..<arrBlockingSchedule.count{
                                arrBlockingSchedule[i].state = .off
                            }
                        }
                        
                        startCustomBlockingSchedule(index: i)
                        break;
                    }else{
                        if arrBlockingSchedule[i].state == .pause{
                            isAnyCustomSchedulePaused = false
                        }
                        arrBlockingSchedule[i].state = .off
                        floatingTopBarVcObj?.boxCustomBlockingSchedule.isHidden = true
                    }
                }else{
                    if arrBlockingSchedule[i].state == .pause{
                        isAnyCustomSchedulePaused = false
                    }
                    arrBlockingSchedule[i].state = .off
                    floatingTopBarVcObj?.boxCustomBlockingSchedule.isHidden = true
                }
            }
        }
    }
    
    func customBlockingScheduleFinished(){
        addLog(text: "Custom blocking schedule finished.")
        for i in 0..<arrBlockingSchedule.count{
            arrBlockingSchedule[i].state = .off
        }
        isAnyCustomScheduleOn = false
        isAnyCustomSchedulePaused = false
        customBlockingDeactivated()
        allApiObject.capturePosthog(event: "finish-blocking-schedule", metadata: [:])//2.27.421
    }
    
    func customBlockingSchedulePaused(){
        addLog(text: "Custom blocking schedule paused.")
        for i in 0..<arrBlockingSchedule.count{
            if arrBlockingSchedule[i].state == .on{
                arrBlockingSchedule[i].state = .pause
                break;
            }
        }
        isAnyCustomScheduleOn = false
        isAnyCustomSchedulePaused = true
        customBlockingDeactivated()
        allApiObject.capturePosthog(event: "pause-blocking-schedule", metadata: [:])//2.27.421
    }
    
    func customBlockingDeactivated(){
        addLog(text: "Custom blocking schedule deactivated.")//2.27.421
        currentScheduleFinishTime = nil
        setAppIconForFocusModeScore(probability: nil)
        isSkipBreakActivityDuringFocus = false
        lastFocusModeTempInfo = nil
        unfocusedTime = 0
        refreshFocusModeData()
        arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()
        menuViewControllerObj?.reloadIfNeeded()
        closeNudgeFocusAlignmentScoreWindow()
        if taskPlayerVcObj != nil && mainWindowControllerObj?.window?.isVisible ?? false{
            if leftMenuVcObj?.boxTodoPlayer.isSelected ?? false{
                mainWindowControllerObj?.window?.close()
            }
        }
        floatingTopBarVcObj?.boxCustomBlockingSchedule.isHidden = true
        leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
        
        if abortingCustomScheduleBlockingVcObj != nil{
            if abortingCustomScheduleBlockingVcObj?.isViewVisible ?? false{
                abortingCustomScheduleBlockingVcObj?.dismiss(abortingCustomScheduleBlockingVcObj)
            }
        }
        if mainWindowControllerObj?.window?.isVisible ?? false{
            if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                if !isFocusModeOn() && !isHardCorePomodoroModeOn{
                    if SettingsManagerObject.isGeekModeEnabled{
                        if pomodoroVcObj != nil{
                            if pomodoroVcObj?.isViewVisible ?? false{
                                leftMenuVcObj?.showPomodoro(pomodoroVcObj: pomodoroVcObj!.view)
                            }
                        }
                    }else if simplePomodoroVcObj != nil{
                        if simplePomodoroVcObj?.isViewVisible ?? false{
                            leftMenuVcObj?.showPomodoro(pomodoroVcObj: simplePomodoroVcObj!.view)
                        }
                    }
                }
            }
        }
    }
    
    // Finish the current custom blocking schedule if its end time has passed
    func checkAndFinishScheduleIfNeeded(){// added 2.29.460
        guard isAnyCustomScheduleOn else { return }
        guard let currentScheduleFinishTime = currentScheduleFinishTime else{
            return;
        }
        if Date() >= currentScheduleFinishTime {
            customBlockingScheduleFinished()
        }
    }
    
    func updateEditedBlockingScheduleEndTimeIfRunning(index:Int){
        if arrBlockingSchedule[index].state == .on{
            let remaining = arrBlockingSchedule[index].remainingBlockingDuration()
            currentScheduleFinishTime = Date() + remaining
            
            showCustomBlockingScheduleStartPopUp(scheduleName: arrBlockingSchedule[index].name, scheduleTime: "\(arrBlockingSchedule[index].startTime.formattedTime()) to \(arrBlockingSchedule[index].endTime.formattedTime())")
        }
    }
    
    func startCustomBlockingSchedule(index:Int){
        addLog(text: "Custom blocking schedule started.")
        arrBlockingSchedule[index].state = .on
        isAnyCustomScheduleOn = true
        isAnyCustomSchedulePaused = false
        endFocusModeTime = arrBlockingSchedule[index].endTime// no mean here 
        var stringTime = ""
        if let date = endFocusModeTime{
            stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
        }
        addLog(text: "Custom blocking schedule Started until - \(stringTime).")
        let remaining = arrBlockingSchedule[index].remainingBlockingDuration()
        currentScheduleFinishTime = Date() + remaining

        for focusMode in arrFocusType{
            if focusMode["id"] as? String == arrBlockingSchedule[index].focusModeID{
                currentRunningFocusType = focusMode
                break;
            }
        }
        
        let lastIntentionUsed = currentRunningFocusType["lastIntentionUsed"] as? String ?? ""
        whatToAchieveInFocusBlock = lastIntentionUsed
        focusModeTaskString = currentRunningFocusType["lastTaskUsed"] as? String ?? ""
        taskCreatedByBlockPopup = ""
        currentFocusModeStrictness = arrBlockingSchedule[index].blockLevel
        startFocusModeTime = Date()
        minFocusAlignmentScoreToShowDistractingPopUp = Double(currentRunningFocusType["focusAlignmentScoreThreshold"] as? Int ?? 80)
        if SettingsManagerObject.isDataCollectionModeEnabled{
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }
        
        arrFocusBlockNotificationShownForApps.removeAll()
        currentRunningAppNameForAi = ""
        currentBrowserUrlForAi = ""
        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus.removeAll()
        tabMatricsObject.last30SecondsDurationRecordedStartTime = Date()
        arrConvinceAiUrlsInCurrentFocus.removeAll()
        arrConvinceAiAppsInCurrentFocus.removeAll()
        lastEntryInProductivityStatsTime = Date()
        tabMatricsObject.resetAll()
        lastFocusAlignmentShownScore = minFocusAlignmentScoreToShowDistractingPopUp
        isMeetingsFocusStartedAutomatically = false
        focusModeActualDurationPerformed = 0
        unfocusedTime = 0
        lastFocusModeTempInfo = nil
        stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
        refreshFocusModeData()
        arrKeywordsToAllowInFocus.removeAll()
        arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
        menuViewControllerObj?.reloadIfNeeded()
        appdelegate!.frontApplicationChanged()// call it because front application is active already
        
        focusModeMinutesToPerform = Int(remaining / 60)
        if !getTaskPlayerVcObject().isViewLoaded{
            getTaskPlayerVcObject().loadView()
        }
        getTaskPlayerVcObject().loadRequest()
        shouldReloadTaskPlayer = true
        
        showCustomBlockingScheduleStartPopUp(scheduleName: arrBlockingSchedule[index].name, scheduleTime: "\(arrBlockingSchedule[index].startTime.formattedTime()) to \(arrBlockingSchedule[index].endTime.formattedTime())")
        leftMenuVcObj?.focusModeOrFocusModeHabitStarted()
        allApiObject.capturePosthog(event: "start-blocking-schedule", metadata: [:])//2.27.421
        
        if floatingTopBarVcObj != nil {
            floatingTopBarVcObj?.boxMain.isHidden = false
            floatingTopBarVcObj?.boxMoreItems.isHidden = false
        }
        
        if mainWindowControllerObj?.window?.isVisible ?? false{
            if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                if !isFocusModeOn() && !isHardCorePomodoroModeOn{
                    if SettingsManagerObject.isGeekModeEnabled{
                        if pomodoroVcObj != nil{
                            if pomodoroVcObj?.isViewVisible ?? false{
                                leftMenuVcObj?.showPomodoro(pomodoroVcObj: pomodoroVcObj!.view)
                            }
                        }
                    }else if simplePomodoroVcObj != nil{
                        if simplePomodoroVcObj?.isViewVisible ?? false{
                            leftMenuVcObj?.showPomodoro(pomodoroVcObj: simplePomodoroVcObj!.view)
                        }
                    }
                }
            }
        }
    }
    
    func saveCustomBlockingScheduleData(){
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(arrBlockingSchedule.first!) else { return }
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
    
    func addCustomBlockingScheduleAtIndex(_ index: Int){
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(arrBlockingSchedule[index]) else { return }
        if let jsonString = String(data: jsonData, encoding: .utf8) {//
            print(jsonString)
            addLog(text: "Blocking schedule added:- \(jsonString)")
        }
        allApiObject.addBlockingSchedule(jsonData: jsonData, completionHandler: {bool in
            
        })
    }
    
    func updateCustomBlockingScheduleAtIndex(_ index: Int){
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(arrBlockingSchedule[index]) else { return }
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {//
            print(jsonString)
            addLog(text: "Blocking schedule updated:- \(jsonString)")
        }
        allApiObject.updateBlockingSchedule(id: arrBlockingSchedule[index].id, jsonData: jsonData, completionHandler: {bool in
            
        })
    }
    
    
    
//    func readCustomBlockingScheduleData(jsonData:Data){
//        if let jsonString = String(data: jsonData, encoding: .utf8) {//
//            print(jsonString)
//        }
//        let decoder = JSONDecoder()
//        if let schedule = try? decoder.decode([customBlockingSchedule].self, from: jsonData){
//            arrBlockingSchedule = schedule
//        }
//    }
    func readCustomBlockingScheduleData(jsonData: Data) {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            addLog(text: "Read Custom Blocking Schedule Data: \(jsonString)")
        }

        let decoder = JSONDecoder()

        do {
            let schedule = try decoder.decode([customBlockingSchedule].self, from: jsonData)
            arrBlockingSchedule = schedule
        } catch {
            addLog(text: "❌ Failed to decode customBlockingSchedule")
            addLog(text: "Error: \(error.localizedDescription)")

            // Optional: detailed decoding error info
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    addLog(text: "Type mismatch for type \(type): \(context.debugDescription)")
                    addLog(text: "Coding path: \(context.codingPath)")

                case .valueNotFound(let type, let context):
                    addLog(text: "Value not found for type \(type): \(context.debugDescription)")
                    addLog(text: "Coding path: \(context.codingPath)")

                case .keyNotFound(let key, let context):
                    addLog(text: "Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    addLog(text: "Coding path: \(context.codingPath)")

                case .dataCorrupted(let context):
                    addLog(text: "Data corrupted: \(context.debugDescription)")
                    addLog(text: "Coding path: \(context.codingPath)")

                @unknown default:
                    addLog(text: "Unknown decoding error")
                }
            }
        }
    }

    
    
    func validateBlockingSchedules() {
        if arrFocusType.count == 0 || arrBlockingSchedule.count == 0{
            return;
        }
        
        let validFocusModeIDs = arrFocusType.compactMap { $0["id"] as? String }
        
        // Identify invalid schedules (those with missing focus mode)
        let invalidSchedules = arrBlockingSchedule.filter {
            !validFocusModeIDs.contains($0.focusModeID)
        }
        
        // Call remove API for each invalid schedule
        for schedule in invalidSchedules {
            removeBlockingScheduleFromServer(schedule: schedule)
        }
        
        // Remove them from local list
        arrBlockingSchedule.removeAll {
            !validFocusModeIDs.contains($0.focusModeID)
        }
    }
    
    func validateBlockingScheduleFocusId(schedule: customBlockingSchedule)->Bool {
        let currentFocusModeID = schedule.focusModeID
        
        // Check if any focus mode in arrFocusType has the same id
        let focusModeExists = arrFocusType.contains { focus in
            if let id = focus["id"] as? String {
                return id == currentFocusModeID
            }
            return false
        }
        
        return focusModeExists
    }
    
    
    func removeBlockingScheduleFromServer(schedule: customBlockingSchedule){
        allApiObject.deleteBlockingSchedule(id: schedule.id, completionHandler: {bool in
            
        })
    }
    
    
    func isAIBlockingEnabled()->Bool{
        if isAnyCustomScheduleOn{
            for schedule in arrBlockingSchedule{
                if schedule.state == .on{
                    return schedule.isAIBlockingEnabled
                }
            }
        }
        return false
    }
    func isMicroBreaksEnabled()->Bool{
        if isAnyCustomScheduleOn{
            for schedule in arrBlockingSchedule{
                if schedule.state == .on{
                    return schedule.isMicroBreaksEnabled
                }
            }
        }
        return false
    }
    
    
    func deleteScheduleAt(_ index:Int){
        allApiObject.capturePosthog(event: "delete-blocking-schedule", metadata: [:])//2.27.421
        if arrBlockingSchedule[index].state == .on{
            customBlockingScheduleFinished()
        }
        
        if arrBlockingSchedule[index].state == .pause{
            isAnyCustomSchedulePaused = false
            menuViewControllerObj?.reloadIfNeeded()
        }
        allApiObject.deleteBlockingSchedule(id: arrBlockingSchedule[index].id, completionHandler: {bool in
            
        })
        arrBlockingSchedule.remove(at: index)
    }
    
    func isStrictnessLevelNormal()->Bool{
        if isAnyCustomScheduleOn{
            for schedule in arrBlockingSchedule{
                if schedule.state == .on{
                    if schedule.blockLevel == ._SUPER_STRICT_{
                        return false
                    }
                    break;
                }
            }
        }
        return true
    }
    
    func isBlockingScheduleOverlapping(
        newSchedule: customBlockingSchedule,
        schedules: [customBlockingSchedule],
        excludingId: String? = nil
    ) -> Bool {
        let calendar = Calendar.current
        
        // Normalize times (handle cross-midnight case)
        func normalizedRange(for schedule: customBlockingSchedule) -> (Date, Date) {
            let start = schedule.startTime
            var end = schedule.endTime
            if end <= start {
                end = calendar.date(byAdding: .day, value: 1, to: end)!
            }
            return (start, end)
        }
        
        // For each day the new schedule applies to
        for newDay in newSchedule.daysOfWeek {
            let (newStartNorm, newEndNorm) = normalizedRange(for: newSchedule)
            
            for existing in schedules {
                // Skip comparing with itself
                if existing.id == excludingId { continue }
                
                // Only compare if they share any common day
                if existing.daysOfWeek.contains(newDay) {
                    let (existingStart, existingEnd) = normalizedRange(for: existing)
                    
                    // Overlap check logic
                    if (newStartNorm < existingEnd && newEndNorm > existingStart) {
                        return true // Overlaps found
                    }
                }
            }
        }
        
        return false
    }

}
