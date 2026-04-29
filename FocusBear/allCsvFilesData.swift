//
//  allCSVFilesData.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/03/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

var quantityCsvURL:URL!
var offlineActivitiesCsvURL:URL!
var focusAlignmentScoreCsvURL:URL!
var focusAIDecisionsCsvURL:URL!
var focusProductivityStatsCsvURL:URL!
var browsersTabAuditCsvURL:URL!
var usageTimingsExplanationCsvUrl:URL!


var csvLoggerProductivityStatsCsv: CSVLogger?
var csvLoggerFocusAIDecisionsCsv: CSVLogger?
var csvLoggerFocusAlignmentScoreCsv: CSVLogger?
var csvLoggerStatsCsv: CSVLogger?
var csvLoggerOfflineActivitiesCsv: CSVLogger?
var csvLoggerUsageTimingsExplanationCsv: CSVLogger?




func checkAllCsvFiles(){
    let fileManager = FileManager.default
    
    if !fileManager.fileExists(atPath: quantityCsvURL.path){
        let csvString = "Log type,Timestamp,Activity,Duration in seconds,Quantity Question,Quantity Logged,Start Time,Work achieved,Distractions encountered,Abort reason,Feedback,Tags\n"//start time will only be use in focus block start k time per
        
        do {
            try csvString.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
        UserDefaults.standard.set(true, forKey: kUserdefaultsTagsColumnAddedInStatsCsv)
    }else if UserDefaults.standard.object(forKey: kUserdefaultsTagsColumnAddedInStatsCsv) == nil{
        
        addTagsColumnInStatsCsv()
        UserDefaults.standard.set(true, forKey: kUserdefaultsTagsColumnAddedInStatsCsv)
    }
    
    
    if !fileManager.fileExists(atPath: focusAlignmentScoreCsvURL.path){
        let csvString = "Timestamp,Url,TabTitle,FocusMode,Intention,AiReason,Probability,TotalScore\n"
        
        do {
            try csvString.write(to: focusAlignmentScoreCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }
    
    if !fileManager.fileExists(atPath: focusAIDecisionsCsvURL.path){
        let csvString = "Timestamp,Url,Domain,TabTitle,AIRelevanceScore,AdditionalUserJustification,currentTaskName,focusIntention,AIReason\n"
        
        do {
            try csvString.write(to: focusAIDecisionsCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }
    
    if !fileManager.fileExists(atPath: focusProductivityStatsCsvURL.path){
        let csvString = "Timestamp,FocusAlignmentScore,AverageTabCount,AverageTabDuration,IdleTimeSeconds,CurrentFocusAlignmentScore,CurrentTabCount,AverageTabDurationInLast30Seconds\n"
        
        do {
            try csvString.write(to: focusProductivityStatsCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }
    
    if !fileManager.fileExists(atPath: offlineActivitiesCsvURL.path){
        let csvString = "activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,skipped_did_complete,choice_id,quantity_logged,skipped_did_not_complete,note_logged\n"//start time will only be use in focus block start k time per
        
        do {
            try csvString.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
        UserDefaults.standard.set(true, forKey: kUserdefaultsNotesAddedInOfflineCsv)
    }else if UserDefaults.standard.object(forKey: kUserdefaultsNotesAddedInOfflineCsv) == nil{
        
        addNotesColumnInOfflineCsv()
        UserDefaults.standard.set(true, forKey: kUserdefaultsNotesAddedInOfflineCsv)
    }
    

    if !fileManager.fileExists(atPath: usageTimingsExplanationCsvUrl.path){
        let csvString = "start_time,end_time,tab_url/app_name,duration_seconds\n"
        
        do {
            try csvString.write(to: usageTimingsExplanationCsvUrl, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }
    
    csvLoggerProductivityStatsCsv = CSVLogger(fileURL: focusProductivityStatsCsvURL)
    
    csvLoggerFocusAIDecisionsCsv = CSVLogger(fileURL: focusAIDecisionsCsvURL)
    
    csvLoggerFocusAlignmentScoreCsv = CSVLogger(fileURL: focusAlignmentScoreCsvURL)
    
    csvLoggerStatsCsv = CSVLogger(fileURL: quantityCsvURL)
    
    csvLoggerOfflineActivitiesCsv = CSVLogger(fileURL: offlineActivitiesCsvURL)
    
    csvLoggerUsageTimingsExplanationCsv = CSVLogger(fileURL: usageTimingsExplanationCsvUrl)
}


func closeAllCsvFiles(){
    csvLoggerProductivityStatsCsv?.close()
    csvLoggerFocusAIDecisionsCsv?.close()
    csvLoggerFocusAlignmentScoreCsv?.close()
    csvLoggerStatsCsv?.close()
    csvLoggerOfflineActivitiesCsv?.close()
    csvLoggerUsageTimingsExplanationCsv?.close()
}



//stast CSV new entry
func addEntryInofflineActivitiesCsv(activity_id:String, duration_logged:String, device_id:String, activity_sequence_id:String, start_time:String, finish_time:String, skipped_did_complete:String, choice_id:String, quantity_logged:String, skipped_did_not_complete:String, note_logged:String ){
    addLog(text: "addEntryInofflineActivitiesCsv activity_id:- \(activity_id)")
    
    if !FileManager.default.fileExists(atPath: offlineActivitiesCsvURL.path){
        let csvString = "activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,skipped_did_complete,choice_id,quantity_logged,skipped_did_not_complete,note_logged\n"
        
        do {
            try csvString.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
            csvLoggerOfflineActivitiesCsv?.close()
            csvLoggerOfflineActivitiesCsv = nil
            csvLoggerOfflineActivitiesCsv = CSVLogger(fileURL: offlineActivitiesCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    let csvString = "\(activity_id),\(duration_logged),\(device_id),\(activity_sequence_id),\(start_time),\(finish_time),\(skipped_did_complete),\(choice_id),\(quantity_logged),\(skipped_did_not_complete),\(note_logged)\n"
    csvLoggerOfflineActivitiesCsv?.append(line: csvString)
}


//stast CSV new entry
func addEntryInStatsCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String, tags:String){
    
    
    if !FileManager.default.fileExists(atPath: quantityCsvURL.path){
        let csvString = "Log type,Timestamp,Activity,Duration in seconds,Quantity Question,Quantity Logged,Start Time,Work achieved,Distractions encountered,Abort reason,Feedback,Tags\n"
        
        do {
            try csvString.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
            csvLoggerStatsCsv?.close()
            csvLoggerStatsCsv = nil
            csvLoggerStatsCsv = CSVLogger(fileURL: quantityCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    
    let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback),\(tags)\n"
    csvLoggerStatsCsv?.append(line: csvString)
}



//stast CSV new entry
func addEntryInfocusAlignmentScoreCsv(url:String, tabTitle:String, focusMode:String, intention:String, aiReason:String, allowedProbability:String, totalScore:String){
    
    if !FileManager.default.fileExists(atPath: focusAlignmentScoreCsvURL.path){
        let csvString = "Timestamp,Url,TabTitle,FocusMode,Intention,AiReason,Probability,TotalScore\n"
        
        do {
            try csvString.write(to: focusAlignmentScoreCsvURL, atomically: true, encoding: .utf8)
            csvLoggerFocusAlignmentScoreCsv?.close()
            csvLoggerFocusAlignmentScoreCsv = nil
            csvLoggerFocusAlignmentScoreCsv = CSVLogger(fileURL: focusAlignmentScoreCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    
    let csvString = "\"\(timestamp)\",\"\(url)\",\"\(tabTitle)\",\"\(focusMode)\",\"\(intention)\",\"\(aiReason)\",\"\(allowedProbability)\",\"\(totalScore)\"\n"
    csvLoggerFocusAlignmentScoreCsv?.append(line: csvString)
}



//stast CSV new entry
func addEntryInFocusAIDecisionsCsv(url:String, domain:String, tabTitle:String, score:String, intention:String, aiReason:String, currentTaskName:String, additionalUserJustification:String){
    
    
    if !FileManager.default.fileExists(atPath: focusAIDecisionsCsvURL.path){
        let csvString = "Timestamp,Url,Domain,TabTitle,AIRelevanceScore,AdditionalUserJustification,currentTaskName,focusIntention,AIReason\n"
        
        do {
            try csvString.write(to: focusAIDecisionsCsvURL, atomically: true, encoding: .utf8)
            csvLoggerFocusAIDecisionsCsv?.close()
            csvLoggerFocusAIDecisionsCsv = nil
            csvLoggerFocusAIDecisionsCsv = CSVLogger(fileURL: focusAIDecisionsCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    
    let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    let csvString = "\"\(timestamp)\",\"\(url)\",\"\(domain)\",\"\(tabTitle)\",\"\(score)\",\"\(additionalUserJustification)\",\"\(currentTaskName)\",\"\(intention)\",\"\(aiReason)\"\n"
    csvLoggerFocusAIDecisionsCsv?.append(line: csvString)
}




func addEntryInProductivityStatsCsv(isoString: String, currentFocusAlignmentScore: Double, averageTabCount: Int, averageTabDuration: Int, idleTimeValue: Int, averageScoreFromLastEntry: Double, currentAppTabCount: Int, last30SecondsAverageTabDurationString: String){
    
    if !FileManager.default.fileExists(atPath: focusProductivityStatsCsvURL.path){
        let csvString = "Timestamp,FocusAlignmentScore,AverageTabCount,AverageTabDuration,IdleTimeSeconds,CurrentFocusAlignmentScore,CurrentTabCount,AverageTabDurationInLast30Seconds\n"
        
        do {
            try csvString.write(to: focusProductivityStatsCsvURL, atomically: true, encoding: .utf8)
            csvLoggerProductivityStatsCsv?.close()
            csvLoggerProductivityStatsCsv = nil
            csvLoggerProductivityStatsCsv = CSVLogger(fileURL: focusProductivityStatsCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    
    let csvString = "\(isoString),\(currentFocusAlignmentScore),\(averageTabCount),\(averageTabDuration),\(idleTimeValue),\(averageScoreFromLastEntry),\(currentAppTabCount),\(last30SecondsAverageTabDurationString)\n"
    csvLoggerProductivityStatsCsv?.append(line: csvString)
}





func addEntriesInUsageTimingsExplanationCsv(arrAllCsvLinesToAdd:[String]){
    if !FileManager.default.fileExists(atPath: usageTimingsExplanationCsvUrl.path){
        let csvString = "start_time,end_time,tab_url/app_name,duration_seconds\n"
        
        do {
            try csvString.write(to: usageTimingsExplanationCsvUrl, atomically: true, encoding: .utf8)
            csvLoggerUsageTimingsExplanationCsv?.close()
            csvLoggerUsageTimingsExplanationCsv = nil
            csvLoggerUsageTimingsExplanationCsv = CSVLogger(fileURL: usageTimingsExplanationCsvUrl)
        } catch {
            print("error creating file")
        }
    }
    
    csvLoggerUsageTimingsExplanationCsv?.append(lines: arrAllCsvLinesToAdd)
}


//

//CSV replace Last entry
func replaceLastEntryInActivitiesCsv(activity_id:String, duration_logged:String, device_id:String, activity_sequence_id:String, start_time:String, finish_time:String, skipped_did_complete:String, choice_id:String, quantity_logged:String, skipped_did_not_complete:String ){
    do {
        var csv = try String(contentsOf: offlineActivitiesCsvURL, encoding: .utf8)
        //        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(activity_id),\(duration_logged),\(device_id),\(activity_sequence_id),\(start_time),\(finish_time),\(skipped_did_complete),\(choice_id),\(quantity_logged),\(skipped_did_not_complete)\n"
        
        csv = csv.replaceLastLineWith(newLine: csvString)
        
        do {
            try csv.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


//CSV replace Last entry
func replaceLastEntryInStatsCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String ){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback)\n"
        
        csv = csv.replaceLastLineWith(newLine: csvString)
        
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}

func addTagsColumnInStatsCsv(){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        
        if let data = csv.addCoulumn(name: "Tags"){
            csv = data
        }else{
            return;
        }
        
        
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
    
}

func removeEntryInActivitiesCsv(count:Int){
    do {
        var csv = try String(contentsOf: offlineActivitiesCsvURL, encoding: .utf8)
        csv = csv.removeEntries(count: count)
        
        do {
            try csv.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


func addNotesColumnInOfflineCsv(){
    do {
        var csv = try String(contentsOf: offlineActivitiesCsvURL, encoding: .utf8)
        
        if let data = csv.addCoulumn(name: "note_logged"){
            csv = data
        }else{
            return;
        }
        
        
        do {
            try csv.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
    
}
final class CSVLogger {

    private let fileURL: URL
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "csv.logger.queue")

    init(fileURL: URL) {
        self.fileURL = fileURL
        prepareFile()
    }

    // -------------------------
    // Setup
    // -------------------------
    private func prepareFile() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        do {
            fileHandle = try FileHandle(forWritingTo: fileURL)

            if #available(macOS 10.15.4, *) {
                try fileHandle?.seekToEnd()
            } else {
                fileHandle?.seekToEndOfFile()
            }

        } catch {
            print("CSVLogger init error: \(error)")
        }
    }

    // -------------------------
    // Append
    // -------------------------
    func append(line: String) {
        guard let data = line.data(using: .utf8) else { return }

        queue.async { [weak self] in
            guard let self = self, let handle = self.fileHandle else { return }

            do {
                if #available(macOS 10.15.4, *) {
                    try handle.write(contentsOf: data)
                } else {
                    handle.write(data)
                }
            } catch {
                print("CSV append error: \(error)")
            }
        }
    }

    func append(lines: [String]) {
        let batchContent = lines.joined(separator: "\n") + "\n"
        
        guard let data = batchContent.data(using: .utf8) else { return }
        
        queue.async { [weak self] in
            guard let self = self, let handle = self.fileHandle else { return }
            
            do {
                if #available(macOS 10.15.4, *) {
                    try handle.write(contentsOf: data)
                } else {
                    handle.write(data)
                }
            } catch {
                print("CSV append error: \(error)")
            }
        }
    }


    
    // -------------------------
    // Close (important!)
    // -------------------------
    func close() {
        queue.sync {
            guard let handle = fileHandle else { return }

            if #available(macOS 10.15.4, *) {
                try? handle.close()
            } else {
                handle.closeFile()
            }

            fileHandle = nil
        }
    }
}




extension String {
    
    func addCoulumn(name:String)->String? {
        let comps = self.split(separator: "\n")
        var outputString = ""
        for i in 0..<comps.count {
            let sub = comps[i]
            if i == 0{
                if String(sub).contains(name){
                    return nil
                }else{
                    outputString.append(String(sub) + ",\(name)" + "\n")
                }
            }else{
                outputString.append(String(sub) + "," + "\n")
            }
            
        }
        return outputString
    }
    
    func replaceLastLineWith(newLine:String)->String {
        var comps = self.split(separator: "\n")
        comps.removeLast()
        var outputString = ""
        //        var br = "\n"
        for sub in comps {
            outputString.append(String(sub)+"\n")
        }
        outputString = outputString.appending(newLine)
        return outputString
    }
    func removeEntries(count:Int)->String {
        var comps = self.split(separator: "\n")
        for i in 1...count{
            comps.remove(at: 1)
        }
        var outputString = ""
        for sub in comps {
            outputString.append(String(sub)+"\n")
        }
        return outputString
    }
}


//stast CSV new entry
func saveBrowsersTabAuditCsv(arrTabs:[(String,String)]){
    if browsersTabAuditCsvURL != nil{
        do{
            try FileManager.default.removeItem(at: browsersTabAuditCsvURL!)
        }catch{
            
        }
    }
    var csv = "URL,Title,Notes\n"
    for tabEntry in arrTabs{
        let csvString = "\"\(tabEntry.1)\",\"\(tabEntry.0)\",\"\"\n"
        csv = csv.appending(csvString)
    }
    
    do {
        try csv.write(to: browsersTabAuditCsvURL, atomically: true, encoding: .utf8)
    } catch {
        print("error creating file")
    }
}


func deleteAllCsvFiles(){
    if quantityCsvURL != nil{
        do{
            try FileManager.default.removeItem(at: quantityCsvURL!)
        }catch{
            
        }
    }
    if offlineActivitiesCsvURL != nil{
        do{
            try FileManager.default.removeItem(at: offlineActivitiesCsvURL!)
        }catch{
            
        }
    }
    if focusAlignmentScoreCsvURL != nil{
        do{
            try FileManager.default.removeItem(at: focusAlignmentScoreCsvURL!)
        }catch{
            
        }
    }
    
    
    if focusAIDecisionsCsvURL != nil{
        do{
            try FileManager.default.removeItem(at: focusAIDecisionsCsvURL!)
        }catch{
            
        }
    }
    
    if focusProductivityStatsCsvURL != nil{
        do{
            try FileManager.default.removeItem(at: focusProductivityStatsCsvURL!)
        }catch{
            
        }
    }

    if usageTimingsExplanationCsvUrl != nil{
        do{
            try FileManager.default.removeItem(at: usageTimingsExplanationCsvUrl!)
        }catch{
            
        }
    }
}
