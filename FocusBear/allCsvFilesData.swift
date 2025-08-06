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

//stast CSV new entry
func addEntryInofflineActivitiesCsv(activity_id:String, duration_logged:String, device_id:String, activity_sequence_id:String, start_time:String, finish_time:String, skipped_did_complete:String, choice_id:String, quantity_logged:String, skipped_did_not_complete:String, note_logged:String ){
    addLog(text: "addEntryInofflineActivitiesCsv activity_id:- \(activity_id)")
    do {
        var csv = try String(contentsOf: offlineActivitiesCsvURL, encoding: .utf8)
        
        //let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(activity_id),\(duration_logged),\(device_id),\(activity_sequence_id),\(start_time),\(finish_time),\(skipped_did_complete),\(choice_id),\(quantity_logged),\(skipped_did_not_complete),\(note_logged)\n"
        csv = csv.appending(csvString)
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

func addTagsEntryInStatsCsv(){
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

func addNotesEntryInOfflineCsv(){
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
//stast CSV new entry
func addEntryInStatsCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String, tags:String){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback),\(tags)\n"
        csv = csv.appending(csvString)
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}

//stast CSV new entry
func addEntryInfocusAlignmentScoreCsv(url:String, tabTitle:String, focusMode:String, intention:String, aiReason:String, allowedProbability:String, totalScore:String){
    do {
        var csv = try String(contentsOf: focusAlignmentScoreCsvURL, encoding: .utf8)
        
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\"\(timestamp)\",\"\(url)\",\"\(tabTitle)\",\"\(focusMode)\",\"\(intention)\",\"\(aiReason)\",\"\(allowedProbability)\",\"\(totalScore)\"\n"
        csv = csv.appending(csvString)
        do {
            try csv.write(to: focusAlignmentScoreCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


//stast CSV new entry
func addEntryInFocusAIDecisionsCsv(url:String, domain:String, tabTitle:String, score:String, intention:String, aiReason:String, currentTaskName:String, additionalUserJustification:String){
    do {
        var csv = try String(contentsOf: focusAIDecisionsCsvURL, encoding: .utf8)
        
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\"\(timestamp)\",\"\(url)\",\"\(domain)\",\"\(tabTitle)\",\"\(score)\",\"\(additionalUserJustification)\",\"\(currentTaskName)\",\"\(intention)\",\"\(aiReason)\"\n"
        csv = csv.appending(csvString)
        do {
            try csv.write(to: focusAIDecisionsCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


var lastEntryInProductivityStatsTime:Date?
func addEntryInProductivityStatsCsv(){
    
    if !SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
        return;
    }
    let currentDate = Date()
    if let lastEntryInProductivityStatsTime = lastEntryInProductivityStatsTime {
        let diffSeconds = currentDate.timeIntervalSince(lastEntryInProductivityStatsTime)
        if diffSeconds < 2.6 {//Log focusProductivityStats.csv every 3 seconds instead of every 10 seconds #1378
            return// this will always show gap of 3 seconds between each entry
        }
//        print(diffSeconds)
    }
    let averageScoreFromLastEntry = getFocusAlignmentScoreFromLastEntry()

    lastEntryInProductivityStatsTime = currentDate
    do {
        var csv = try String(contentsOf: focusProductivityStatsCsvURL, encoding: .utf8)
        let date = currentDate
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime] // Standard ISO 8601 format

        let isoString = isoFormatter.string(from: date)
        
        var lastEvent:CFTimeInterval = 0
        lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
        let idleTimeValue = Int(lastEvent)
        var averageTabCount = 0
        var averageTabDuration = 0
//        var averageTabDurationInLast30Seconds = 0
        
        let arrAllTabsCount = tabMatricsObject.arrAllTabsCount
        let sumOfCount =  arrAllTabsCount.reduce(0, +)
        if arrAllTabsCount.count > 0{
            averageTabCount = sumOfCount / arrAllTabsCount.count
        }
        
        var arrAllUrlsRecodDuringFocusMode = tabMatricsObject.arrAllUrlsRecodDuringFocusMode
        var arrAllAppsRecodDuringFocusMode = tabMatricsObject.arrAllAppsRecodDuringFocusMode
        

        arrAllAppsRecodDuringFocusMode = tabMatricsObject.clubAllSameAppEntries(appData: arrAllAppsRecodDuringFocusMode)
        arrAllUrlsRecodDuringFocusMode = tabMatricsObject.clubAllSameDomainEntries(appData: arrAllUrlsRecodDuringFocusMode)
        var arrAllAppsTabsData = arrAllAppsRecodDuringFocusMode
        arrAllAppsTabsData += arrAllUrlsRecodDuringFocusMode
        
        
        
        // Calculate the average duration per tab
        var allAppsWithoutBrowsers = [[String : Any]]()//
        //  ignore browser in average tab count
        for item in arrAllAppsTabsData{
            let isBrowser = item[tabMatricsObject.keyIsBrowser] as? Bool ?? false
            if !isBrowser{
                allAppsWithoutBrowsers.append(item)
            }
        }
        
        let totalDuration = allAppsWithoutBrowsers.reduce(0) { total, entry in
            if let duration = entry["duration"] as? Int {
                return total + duration
            }else{
                print("duration not found:- \(entry["appName"] as? String ?? entry["domain"] as? String ?? "")")
            }
            return total
        }

        averageTabDuration = allAppsWithoutBrowsers.isEmpty ? 0 : totalDuration / allAppsWithoutBrowsers.count

        // calculate averageTabDurationInLast30Seconds // date 22/5/25  // version 1.23.368
        let last30SecondsAverageTabDuration = tabMatricsObject.getLast30SecondsAverageTabDuration()
        let last30SecondsAverageTabDurationString = last30SecondsAverageTabDuration == nil ? "" : "\(String(describing: last30SecondsAverageTabDuration ?? 0))"
        
        //
        
        let csvString = "\(isoString),\(currentFocusAlignmentScore),\(averageTabCount),\(averageTabDuration),\(idleTimeValue),\(averageScoreFromLastEntry),\(tabMatricsObject.currentAppTabCount),\(last30SecondsAverageTabDurationString)\n"
        csv = csv.appending(csvString)
        do {
            try csv.write(to: focusProductivityStatsCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
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
