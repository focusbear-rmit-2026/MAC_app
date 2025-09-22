//
//  PauseFriction.swift
//  FocusBear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Foundation

// MARK: - Enums with API raw values
enum PauseFriction: String, Codable {
    case none
    case timer
    case hundredRandomChars = "100_random_chars"
    case password
}

enum BlockLevel: String, Codable {
    case gentle
    case strict
    case coolDown
}

// MARK: - BlockingSchedule Model
struct customBlockingSchedule: Codable, Identifiable {
    let id: String
    var name: String
    var startTime: Date   // keep as String in "HH:mm" or ISO8601 if API sends like that
    var endTime: Date
    var daysOfWeek: [Int]   // e.g. [1,2,3,4,5]
    var focusModeID: String
    var pauseFriction: PauseFriction
    var blockLevel: BlockLevel
    var isAIBlockingEnabled: Bool
    var isOn = false
    var displayString: String {
        "\(daysOfWeek.formattedDays()), \(startTime.formattedTime()) to \(endTime.formattedTime())"
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
    }
    // Custom decoding/encoding for time strings
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            daysOfWeek = try container.decode([Int].self, forKey: .daysOfWeek)
            focusModeID = try container.decode(String.self, forKey: .focusModeID)
            pauseFriction = try container.decode(PauseFriction.self, forKey: .pauseFriction)
            blockLevel = try container.decode(BlockLevel.self, forKey: .blockLevel)
            isAIBlockingEnabled = try container.decode(Bool.self, forKey: .isAIBlockingEnabled)
            
            let startString = try container.decode(String.self, forKey: .startTime)
            let endString = try container.decode(String.self, forKey: .endTime)
            startTime = customBlockingSchedule.timeFormatter.date(from: startString)!
            endTime = customBlockingSchedule.timeFormatter.date(from: endString)!
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(daysOfWeek, forKey: .daysOfWeek)
            try container.encodeIfPresent(focusModeID, forKey: .focusModeID)
            try container.encode(pauseFriction, forKey: .pauseFriction)
            try container.encode(blockLevel, forKey: .blockLevel)
            try container.encode(isAIBlockingEnabled, forKey: .isAIBlockingEnabled)
            
            try container.encode(customBlockingSchedule.timeFormatter.string(from: startTime), forKey: .startTime)
            try container.encode(customBlockingSchedule.timeFormatter.string(from: endTime), forKey: .endTime)
        }
    
    // Shared formatter for "HH:mm"
        static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
}


extension customBlockingSchedule {
    init(
        name: String,
        start: String,
        end: String,
        daysOfWeek: [Int],
        focusModeID: String,
        pauseFriction: PauseFriction,
        blockLevel: BlockLevel,
        isAIBlockingEnabled: Bool
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.startTime = customBlockingSchedule.timeFormatter.date(from: start)!
        self.endTime = customBlockingSchedule.timeFormatter.date(from: end)!
        self.daysOfWeek = daysOfWeek
        self.focusModeID = focusModeID
        self.pauseFriction = pauseFriction
        self.blockLevel = blockLevel
        self.isAIBlockingEnabled = isAIBlockingEnabled
    }
}

var arrBlockingSchedule = [customBlockingSchedule]()

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
