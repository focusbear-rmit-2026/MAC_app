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

// File names of the CSVs above; SecureStore keeps every one of them sealed (SensitiveKeyRegistry.files).
let kStatsCsvFileName = "eystStats.csv"
let kOfflineActivitiesCsvFileName = "offlineActivities.csv"
let kFocusAlignmentScoreCsvFileName = "focusAlignmentScore.csv"
let kFocusAIDecisionsCsvFileName = "focusAIDecisions.csv"
let kFocusProductivityStatsCsvFileName = "focusProductivityStats.csv"
let kUsageTimingsCsvFileName = "usage_timings.csv"


var csvLoggerProductivityStatsCsv: CSVLogger?
var csvLoggerFocusAIDecisionsCsv: CSVLogger?
var csvLoggerFocusAlignmentScoreCsv: CSVLogger?
var csvLoggerStatsCsv: CSVLogger?
var csvLoggerOfflineActivitiesCsv: CSVLogger?
var csvLoggerUsageTimingsExplanationCsv: CSVLogger?




/// The CSVs `checkAllCsvFiles` creates and `deleteAllCsvFiles` removes, all kept sealed by SecureFiles.
private var allSealedCsvFileURLs: [URL] {
    [quantityCsvURL, offlineActivitiesCsvURL, focusAlignmentScoreCsvURL, focusAIDecisionsCsvURL,
     focusProductivityStatsCsvURL, usageTimingsExplanationCsvUrl].compactMap { $0 }
}

func checkAllCsvFiles(){
    allSealedCsvFileURLs.forEach(SecureFiles.shared.sealPlaintextIfPresent)

    if !SecureFiles.shared.exists(quantityCsvURL){
        let csvString = "Log type,Timestamp,Activity,Duration in seconds,Quantity Question,Quantity Logged,Start Time,Work achieved,Distractions encountered,Abort reason,Feedback,Tags\n"//start time will only be use in focus block start k time per
        
        do {
            try SecureFiles.shared.writeText(csvString, to: quantityCsvURL)
        } catch {
            print("error creating file")
        }
        UserDefaults.standard.set(true, forKey: kUserdefaultsTagsColumnAddedInStatsCsv)
    }else if UserDefaults.standard.object(forKey: kUserdefaultsTagsColumnAddedInStatsCsv) == nil{
        
        addTagsColumnInStatsCsv()
        UserDefaults.standard.set(true, forKey: kUserdefaultsTagsColumnAddedInStatsCsv)
    }
    
    
    if !SecureFiles.shared.exists(focusAlignmentScoreCsvURL){
        let csvString = "Timestamp,Url,TabTitle,FocusMode,Intention,AiReason,Probability,TotalScore\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: focusAlignmentScoreCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    if !SecureFiles.shared.exists(focusAIDecisionsCsvURL){
        let csvString = "Timestamp,Url,Domain,TabTitle,AIRelevanceScore,AdditionalUserJustification,currentTaskName,focusIntention,AIReason\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: focusAIDecisionsCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    if !SecureFiles.shared.exists(focusProductivityStatsCsvURL){
        let csvString = "Timestamp,FocusAlignmentScore,AverageTabCount,AverageTabDuration,IdleTimeSeconds,CurrentFocusAlignmentScore,CurrentTabCount,AverageTabDurationInLast30Seconds\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: focusProductivityStatsCsvURL)
        } catch {
            print("error creating file")
        }
    }
    
    if !SecureFiles.shared.exists(offlineActivitiesCsvURL){
        let csvString = "activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,skipped_did_complete,choice_id,quantity_logged,skipped_did_not_complete,note_logged\n"//start time will only be use in focus block start k time per
        
        do {
            try SecureFiles.shared.writeText(csvString, to: offlineActivitiesCsvURL)
        } catch {
            print("error creating file")
        }
        UserDefaults.standard.set(true, forKey: kUserdefaultsNotesAddedInOfflineCsv)
    }else if UserDefaults.standard.object(forKey: kUserdefaultsNotesAddedInOfflineCsv) == nil{
        
        addNotesColumnInOfflineCsv()
        UserDefaults.standard.set(true, forKey: kUserdefaultsNotesAddedInOfflineCsv)
    }
    

    if !SecureFiles.shared.exists(usageTimingsExplanationCsvUrl){
        let csvString = "start_time,end_time,tab_url/app_name,duration_seconds\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: usageTimingsExplanationCsvUrl)
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
    
    if !SecureFiles.shared.exists(offlineActivitiesCsvURL){
        let csvString = "activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,skipped_did_complete,choice_id,quantity_logged,skipped_did_not_complete,note_logged\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: offlineActivitiesCsvURL)
            csvLoggerOfflineActivitiesCsv?.close()
            csvLoggerOfflineActivitiesCsv = nil
            csvLoggerOfflineActivitiesCsv = CSVLogger(fileURL: offlineActivitiesCsvURL)
        } catch {
            addLog(text: "error creating file")
        }
    }
    
    let csvString = "\(activity_id),\(duration_logged),\(device_id),\(activity_sequence_id),\(start_time),\(finish_time),\(skipped_did_complete),\(choice_id),\(quantity_logged),\(skipped_did_not_complete),\(note_logged)\n"
    csvLoggerOfflineActivitiesCsv?.append(line: csvString)

    // A habit queued here is one the routine player has already moved past — the send just failed. Record
    // it locally as well, so everything that asks "what is left of today's routine" agrees with the player
    // instead of waiting for a server round-trip that, offline, never comes. Until this, the ONLY thing
    // that marked a habit done was the 201 handler, so an offline morning left the Day Plan's capacity
    // still charging for habits the timeline had already turned into deep work: five habits finished
    // offline and the panel read "54m of tasks planned · -5m buffer" beside 71 minutes of drawn deep work
    // (report 2026-09-17_08-56-04). Every row means the habit is out of today's plan — a completion, an
    // "I already did this", or a skip — which is exactly what `offlineCompletedHabitIds()` already reads
    // this file for, and what the action bar's own optimistic skip does.
    let dayKey = offlineActivityLocalDayKey(start_time)
    DispatchQueue.main.async { markPastHabitDoneInDayPlan(id: activity_id, dayKey: dayKey) }
}


//stast CSV new entry
func addEntryInStatsCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String, tags:String){
    
    addLog(text: "Add Entry In Stats Csv")
    if !SecureFiles.shared.exists(quantityCsvURL){
        let csvString = "Log type,Timestamp,Activity,Duration in seconds,Quantity Question,Quantity Logged,Start Time,Work achieved,Distractions encountered,Abort reason,Feedback,Tags\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: quantityCsvURL)
            csvLoggerStatsCsv?.close()
            csvLoggerStatsCsv = nil
            csvLoggerStatsCsv = CSVLogger(fileURL: quantityCsvURL)
        } catch {
            print("error creating file")
            addLog(text: "error creating file")
        }
    }
    
    let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    
    let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback),\(tags)\n"
    csvLoggerStatsCsv?.append(line: csvString)
}



//stast CSV new entry
func addEntryInfocusAlignmentScoreCsv(url:String, tabTitle:String, focusMode:String, intention:String, aiReason:String, allowedProbability:String, totalScore:String){
    
    if !SecureFiles.shared.exists(focusAlignmentScoreCsvURL){
        let csvString = "Timestamp,Url,TabTitle,FocusMode,Intention,AiReason,Probability,TotalScore\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: focusAlignmentScoreCsvURL)
            csvLoggerFocusAlignmentScoreCsv?.close()
            csvLoggerFocusAlignmentScoreCsv = nil
            csvLoggerFocusAlignmentScoreCsv = CSVLogger(fileURL: focusAlignmentScoreCsvURL)
        } catch {
            addLog(text: "error creating file")
        }
    }
    
    let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    
    let csvString = "\"\(timestamp)\",\"\(url)\",\"\(tabTitle)\",\"\(focusMode)\",\"\(intention)\",\"\(aiReason)\",\"\(allowedProbability)\",\"\(totalScore)\"\n"
    csvLoggerFocusAlignmentScoreCsv?.append(line: csvString)
}



//stast CSV new entry
func addEntryInFocusAIDecisionsCsv(url:String, domain:String, tabTitle:String, score:String, intention:String, aiReason:String, currentTaskName:String, additionalUserJustification:String){
    
    
    if !SecureFiles.shared.exists(focusAIDecisionsCsvURL){
        let csvString = "Timestamp,Url,Domain,TabTitle,AIRelevanceScore,AdditionalUserJustification,currentTaskName,focusIntention,AIReason\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: focusAIDecisionsCsvURL)
            csvLoggerFocusAIDecisionsCsv?.close()
            csvLoggerFocusAIDecisionsCsv = nil
            csvLoggerFocusAIDecisionsCsv = CSVLogger(fileURL: focusAIDecisionsCsvURL)
        } catch {
            addLog(text: "error creating file")
        }
    }
    
    
    let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    let csvString = "\"\(timestamp)\",\"\(url)\",\"\(domain)\",\"\(tabTitle)\",\"\(score)\",\"\(additionalUserJustification)\",\"\(currentTaskName)\",\"\(intention)\",\"\(aiReason)\"\n"
    csvLoggerFocusAIDecisionsCsv?.append(line: csvString)
}




func addEntryInProductivityStatsCsv(isoString: String, currentFocusAlignmentScore: Double, averageTabCount: Int, averageTabDuration: Int, idleTimeValue: Int, averageScoreFromLastEntry: Double, currentAppTabCount: Int, last30SecondsAverageTabDurationString: String){
    
    if !SecureFiles.shared.exists(focusProductivityStatsCsvURL){
        let csvString = "Timestamp,FocusAlignmentScore,AverageTabCount,AverageTabDuration,IdleTimeSeconds,CurrentFocusAlignmentScore,CurrentTabCount,AverageTabDurationInLast30Seconds\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: focusProductivityStatsCsvURL)
            csvLoggerProductivityStatsCsv?.close()
            csvLoggerProductivityStatsCsv = nil
            csvLoggerProductivityStatsCsv = CSVLogger(fileURL: focusProductivityStatsCsvURL)
        } catch {
            addLog(text: "error creating file")
        }
    }
    
    
    let csvString = "\(isoString),\(currentFocusAlignmentScore),\(averageTabCount),\(averageTabDuration),\(idleTimeValue),\(averageScoreFromLastEntry),\(currentAppTabCount),\(last30SecondsAverageTabDurationString)\n"
    csvLoggerProductivityStatsCsv?.append(line: csvString)
}





func addEntriesInUsageTimingsExplanationCsv(arrAllCsvLinesToAdd:[String]){
    addLog(text: "Add Entries In UsageTimingsExplanationCsv")
    if !SecureFiles.shared.exists(usageTimingsExplanationCsvUrl){
        let csvString = "start_time,end_time,tab_url/app_name,duration_seconds\n"
        
        do {
            try SecureFiles.shared.writeText(csvString, to: usageTimingsExplanationCsvUrl)
            csvLoggerUsageTimingsExplanationCsv?.close()
            csvLoggerUsageTimingsExplanationCsv = nil
            csvLoggerUsageTimingsExplanationCsv = CSVLogger(fileURL: usageTimingsExplanationCsvUrl)
        } catch {
            addLog(text: "error creating file")
        }
    }
    
    csvLoggerUsageTimingsExplanationCsv?.append(lines: arrAllCsvLinesToAdd)
}


//

//CSV replace Last entry
func replaceLastEntryInActivitiesCsv(activity_id:String, duration_logged:String, device_id:String, activity_sequence_id:String, start_time:String, finish_time:String, skipped_did_complete:String, choice_id:String, quantity_logged:String, skipped_did_not_complete:String ){
    addLog(text: "Replace last entry in activities csv")
    do {
        csvLoggerOfflineActivitiesCsv?.close()   // a queued append must land before the rewrite reads the file
        var csv = try SecureFiles.shared.readText(offlineActivitiesCsvURL)
        //        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(activity_id),\(duration_logged),\(device_id),\(activity_sequence_id),\(start_time),\(finish_time),\(skipped_did_complete),\(choice_id),\(quantity_logged),\(skipped_did_not_complete)\n"
        
        csv = csv.replaceLastLineWith(newLine: csvString)

        do {
            try SecureFiles.shared.writeText(csv, to: offlineActivitiesCsvURL)
        } catch {
            addLog(text: "error write file")
        }
    }catch{
        print(error)
        addLog(text: "error write file:- \(error.localizedDescription)")
    }
}


//CSV replace Last entry
func replaceLastEntryInStatsCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String ){
    addLog(text: "Replace last entry in Stats csv")
    do {
        csvLoggerStatsCsv?.close()   // a queued append must land before the rewrite reads the file
        var csv = try SecureFiles.shared.readText(quantityCsvURL)
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback)\n"
        
        csv = csv.replaceLastLineWith(newLine: csvString)
        
        do {
            try SecureFiles.shared.writeText(csv, to: quantityCsvURL)
        } catch {
            addLog(text: "error write file")
        }
    }catch{
        addLog(text: "error write file:- \(error.localizedDescription)")
    }
}

func addTagsColumnInStatsCsv(){
    addLog(text: "Add Tags Column In Stats Csv")
    do {
        csvLoggerStatsCsv?.close()   // a queued append must land before the rewrite reads the file
        var csv = try SecureFiles.shared.readText(quantityCsvURL)
        
        if let data = csv.addCoulumn(name: "Tags"){
            csv = data
        }else{
            return;
        }
        
        
        do {
            try SecureFiles.shared.writeText(csv, to: quantityCsvURL)
        } catch {
            addLog(text: "error write file")
        }
    }catch{
        addLog(text: "error write file:- \(error.localizedDescription)")
    }
    
}

func removeEntryInActivitiesCsv(count:Int){
    addLog(text: "Remove Entry In Activities Csv")
    do {
        csvLoggerOfflineActivitiesCsv?.close()   // a queued append must land before the rewrite reads the file
        var csv = try SecureFiles.shared.readText(offlineActivitiesCsvURL)
        csv = csv.removeEntries(count: count)

        do {
            try SecureFiles.shared.writeText(csv, to: offlineActivitiesCsvURL)
        } catch {
            addLog(text: "error write file")
        }
    }catch{
        addLog(text: "error write file:- \(error.localizedDescription)")
    }
}


func addNotesColumnInOfflineCsv(){
    addLog(text: "Add notes column in offline csv")
    do {
        csvLoggerOfflineActivitiesCsv?.close()   // a queued append must land before the rewrite reads the file
        var csv = try SecureFiles.shared.readText(offlineActivitiesCsvURL)
        
        if let data = csv.addCoulumn(name: "note_logged"){
            csv = data
        }else{
            return;
        }


        do {
            try SecureFiles.shared.writeText(csv, to: offlineActivitiesCsvURL)
        } catch {
            addLog(text: "error write file")
        }
    }catch{
        addLog(text: "error write file:- \(error.localizedDescription)")
    }

}

/// Appends lines to one of the CSV / JSON-lines files on its own queue, through `SecureFiles` (a sealed
/// record per append for a registered file). It holds no file handle, so a rewrite of the file in
/// between (which replaces its inode) can't strand later appends in the old one.
final class CSVLogger {

    private let fileURL: URL
    private let queue = DispatchQueue(label: "csv.logger.queue")

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func append(line: String) {
        append(Data(line.utf8))
    }

    func append(lines: [String]) {
        append(Data((lines.joined(separator: "\n") + "\n").utf8))
    }

    /// Waits for queued appends to reach the file.
    func close() {
        queue.sync {}
    }

    private func append(_ data: Data) {
        queue.async { [fileURL] in
            do {
                try SecureFiles.shared.append(data, to: fileURL)
            } catch {
                addLog(text: "CSV append error: \(error)")
            }
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
    closeAllCsvFiles()
    allSealedCsvFileURLs.forEach(SecureFiles.shared.remove)
}
