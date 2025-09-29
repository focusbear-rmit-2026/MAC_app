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

//enum BlockLevel: String, Codable {
//    case gentle
//    case strict
//    case coolDown
//}

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
    var isOn = false
    var displayString: String {
        "\(daysOfWeek.formattedDays()), \(startTime.formattedTime()) to \(endTime.formattedTime())"
    }
    var blockLevelString: String {
        switch blockLevel{
            
        case ._NORMAL_:
            "Normal"
        case ._STRICT_:
            "Strict"
        case ._SUPER_STRICT_:
            "Super Strict" // todo text
        }
    }
    
    
    func isBlockingActive() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let schedule = self
        guard schedule.daysOfWeek.contains(weekday) else { return false }

       // let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
       // let nowDate = calendar.date(bySettingHour: nowComponents.hour!, minute: nowComponents.minute!, second: 0, of: now)!

        let startDate = schedule.startTime

        var endDate = schedule.endTime

        // Handle cross-midnight
        if endDate <= startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
        }

        return now >= startDate && now <= endDate
    }
    
    func remainingBlockingDuration() -> TimeInterval {
        let now = Date()
        let start = self.startTime
        let end = endTime
        
        guard now >= start, now < end else {
            return 1
        }
              
        return end.timeIntervalSince(now)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "Name"
        case startTime = "Start_time"
        case endTime = "End_time"
        case daysOfWeek = "Days_of_week"
        case focusModeID = "focus_mode_id"
        case pauseFriction = "Pause_friction"
        case blockLevel = "Block_level"
        case isAIBlockingEnabled = "Is_ai_blocking_enabled"
        case isMicroBreaksEnabled = "Is_micro_breaks_enabled"
    }
    // Custom decoding/encoding for time strings
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            daysOfWeek = try container.decode([Int].self, forKey: .daysOfWeek)
            focusModeID = try container.decode(String.self, forKey: .focusModeID)
//            pauseFriction = try container.decode(PauseFriction.self, forKey: .pauseFriction)
            blockLevel = try container.decode(FOCUSMODESTRICTNESS.self, forKey: .blockLevel)
            isAIBlockingEnabled = try container.decode(Bool.self, forKey: .isAIBlockingEnabled)
            isMicroBreaksEnabled = try container.decode(Bool.self, forKey: .isMicroBreaksEnabled)
            
            startTimeString = try container.decode(String.self, forKey: .startTime)
            endTimeString = try container.decode(String.self, forKey: .endTime)
            startTime = customBlockingSchedule.timeFormatter.date(from: startTimeString)!
            endTime = customBlockingSchedule.timeFormatter.date(from: endTimeString)!
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(daysOfWeek, forKey: .daysOfWeek)
            try container.encodeIfPresent(focusModeID, forKey: .focusModeID)
//            try container.encode(pauseFriction, forKey: .pauseFriction)
            try container.encode(blockLevel, forKey: .blockLevel)
            try container.encode(isAIBlockingEnabled, forKey: .isAIBlockingEnabled)
            
            try container.encode(startTimeString, forKey: .startTime)
            try container.encode(endTimeString, forKey: .endTime)
//            try container.encode(customBlockingSchedule.timeFormatter.string(from: startTime), forKey: .startTime)
//            try container.encode(customBlockingSchedule.timeFormatter.string(from: endTime), forKey: .endTime)
        }
    
    // Shared formatter for "HH:mm"
        static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
    
    static func dateForToday(from timeString: String) -> Date? {
        guard let time = timeFormatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        todayComponents.hour = timeComponents.hour
        todayComponents.minute = timeComponents.minute
        
        return calendar.date(from: todayComponents)
    }
}


extension customBlockingSchedule {
    init(
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
        self.id = UUID().uuidString
        self.name = name
        self.startTimeString = start
        self.endTimeString = end
        self.startTime = Self.dateForToday(from: start) ?? Date()
        self.endTime = Self.dateForToday(from: end) ?? Date()
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
class customBlockingScheduleManager {
    
    var arrBlockingSchedule = [customBlockingSchedule]()
    var isAnyCustomScheduleOn = false
    var customBlockingScheduleIndex = 0
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.dayChangedOperations(_:)), name:NSNotification.Name.NSCalendarDayChanged, object:nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func dayChangedOperations(_ aNotification: Notification) {
        addLog(text: "func call:- dayChangedOperations")
        for i in 0..<arrBlockingSchedule.count {
            arrBlockingSchedule[i].startTime = customBlockingSchedule.timeFormatter.date(from: arrBlockingSchedule[i].startTimeString)!
            arrBlockingSchedule[i].endTime = customBlockingSchedule.timeFormatter.date(from: arrBlockingSchedule[i].endTimeString)!
        }
    }
    
    // todo if user try to start focus mode then stop customBlockingSchedule.
    // same case for morning evening micor break and custom routine
    
    func checkCustomBlockingScheduleTime(){
        if currentState != ._MORNING_HABIT_ && currentState != ._CUSTOM_ROUTINE_ && currentState != ._EVENING_HABIT_ && !appdelegate!.isProcessingHabitRoutine && !isProcessingCustomRoutine && currentState != ._MICRO_BREAK_ && !isAnyCustomScheduleOn{
            for i in 0..<arrBlockingSchedule.count{
                
                if arrBlockingSchedule[i].isBlockingActive(){
                    arrBlockingSchedule[i].isOn = true
                    isAnyCustomScheduleOn = true
                    customBlockingScheduleIndex = i
                    endFocusModeTime = arrBlockingSchedule[i].endTime
                    var stringTime = ""
                    if let date = endFocusModeTime{
                        stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
                    }
                    addLog(text: "Custom blocking schedule Started until - \(stringTime).")
                    let remaining = arrBlockingSchedule[i].remainingBlockingDuration()
                    DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                        self?.customBlockingScheduleFinished()
                    }
                    for focusMode in arrFocusType{
                        if focusMode["id"] as? String == arrBlockingSchedule[i].focusModeID{
                            currentRunningFocusType = focusMode
                            break;
                        }
                    }

                    let lastIntentionUsed = currentRunningFocusType["lastIntentionUsed"] as? String ?? ""
                    whatToAchieveInFocusBlock = lastIntentionUsed
                    focusModeTaskString = currentRunningFocusType["lastTaskUsed"] as? String ?? ""
                    currentFocusModeStrictness = arrBlockingSchedule[i].blockLevel
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
                    menuViewControllerObj?.reloadIfNeeded() // todo stop ka button
                    appdelegate!.frontApplicationChanged()// call it because front application is active already
                    
                    
                    
//                    let minute = textFieldWorkDuration.integerValue
//                    if !getTaskPlayerVcObject().isViewLoaded{
//                        getTaskPlayerVcObject().loadView()
//                    }
//                    taskPlayerVcObj?.reloadData(totalDuration: minute, intention: textViewAchieve.string)
                    shouldReloadTaskPlayer = false
                    break;
                }else{
                    arrBlockingSchedule[i].isOn = false
                }
            }
        }
    }
    
    func customBlockingScheduleFinished(){
        addLog(text: "Custom blocking schedule finished.")
        for i in 0..<arrBlockingSchedule.count{
            arrBlockingSchedule[i].isOn = false
        }
        isAnyCustomScheduleOn = false
        
        setAppIconForFocusModeScore(probability: nil)
        isSkipBreakActivityDuringFocus = false
        lastFocusModeTempInfo = nil
        unfocusedTime = 0
        endFocusModeTime = nil
        refreshFocusModeData()
        arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
        closePupUpBlockIfVisible()
        menuViewControllerObj?.reloadIfNeeded()
        closeNudgeFocusAlignmentScoreWindow()
    }
    
    func saveCustomBlockingScheduleData(){
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(arrBlockingSchedule) else { return }

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }


    func readCustomBlockingScheduleData(jsonData:Data){
        let decoder = JSONDecoder()
        if let schedule = try? decoder.decode([customBlockingSchedule].self, from: jsonData){
            arrBlockingSchedule = schedule
        }
    }
}
