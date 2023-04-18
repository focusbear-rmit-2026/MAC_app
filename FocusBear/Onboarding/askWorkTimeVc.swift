//
//  askWorkTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/02/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class askWorkTimeVc: NSViewController {

  
    @IBOutlet weak var lblQuestionFinishWorkTime: NSTextField!
    @IBOutlet weak var lblQuestionStartWorkTime: NSTextField!
//    @IBOutlet weak var lblDescriptionShutOffTime: NSTextField!
//    @IBOutlet weak var lblDescriptionStartupTime: NSTextField!
//    @IBOutlet weak var lblTitleShutDownTime: NSTextField!
//    @IBOutlet weak var lblTitleStartupTime: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var datePickerShutDownTime: NSDatePicker!
    @IBOutlet weak var datePickerStartTime: NSDatePicker!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
//    @IBOutlet weak var lblStartupTime: NSTextField!
//    @IBOutlet weak var lblShutOfTime: NSTextField!
    
    @IBOutlet weak var lblExplanation: NSTextField!
    var morningRoutineDuration: Int = 0
    var eveningRoutineDuration: Int = 0
    var startUpTime: Date = Date()
    
//    var textStartupTime = "Choose the absolute earliest time you ever plan to start your morning routine. You can start your morning routine at any time after <SHUTOFFTIME>. Before <STARTTIME> your computer will be locked because you should be sleeping 😴 (you can still unlock it if you have an emergency)."
//    var textShutOffTime = "At <SHUTOFFTIME>, Focus Bear will take over your computer and other devices and guide you through your evening routine to help you wind down for the evening."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "Set Startup and Shutdown time"
        btnContinue.title = "Continue"
        lblQuestion.stringValue = "When do you want to start and finish work?"
        
        lblQuestionStartWorkTime.stringValue = "What time do you start work?"
        lblQuestionFinishWorkTime.stringValue = "What time do you finish work?"
//        lblTitleStartupTime.stringValue = "Startup Time:"
//        lblTitleShutDownTime.stringValue = "Shutdown Time:"
        
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
//            lblTitle.stringValue = askAppWorkVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
//            lblTitleStartupTime.stringValue = askWorkTimeVcInfo.value(forKey: "titleStartupTime") as? String ?? lblTitleStartupTime.stringValue
//            lblTitleShutDownTime.stringValue = askWorkTimeVcInfo.value(forKey: "titleShutDownTime") as? String ?? lblTitleShutDownTime.stringValue
            //textStartupTime = askWorkTimeVcInfo.value(forKey: "descriptionStartupTime") as? String ?? textStartupTime
          //  textShutOffTime = askWorkTimeVcInfo.value(forKey: "descriptionShutDownTime") as? String ?? textShutOffTime
            lblQuestion.stringValue = askWorkTimeVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblQuestionStartWorkTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionStartWorkTimeText") as? String ?? lblQuestionStartWorkTime.stringValue
            lblQuestionFinishWorkTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionFinishWorkTimeText") as? String ?? lblQuestionFinishWorkTime.stringValue
        }
        
        
        
        morningRoutineDuration = selectHabitPacksVcObj?.morningRoutineDuration ?? 0
        eveningRoutineDuration = selectHabitPacksVcObj?.eveningRoutineDuration ?? 0
        
        allApiObject.capturePosthog(event: "ask-work-time-shown", metadata: [:])
    }
    
    override func viewWillAppear() {
        datePickerStartTime.dateValue = getDateFromString(date: "8:30", dateFormat: "HH:mm") ?? Date()// same time in abort button
        datePickerShutDownTime.dateValue = getDateFromString(date: "18:30", dateFormat: "HH:mm") ?? Date()
        resetView()
    }
    func resetView(){
        let startTime = datePickerStartTime.dateValue
        let shutOffTime = datePickerShutDownTime.dateValue
        
        let startWorkTimeString = getStringFromDate(date: datePickerStartTime.dateValue, dateFormat: "hh:mm a")
        let endWorkTimeString = getStringFromDate(date: datePickerShutDownTime.dateValue, dateFormat: "hh:mm a")
        
        
       // var descriptionStartupTime = textStartupTime
       // var descriptionShutOffTime = textShutOffTime
        
       // descriptionStartupTime = descriptionStartupTime.replacingOccurrences(of: "<SHUTOFFTIME>", with: endWorkTimeString)
    //    descriptionStartupTime = descriptionStartupTime.replacingOccurrences(of: "<STARTTIME>", with: startWorkTimeString)
        
   //     descriptionShutOffTime = descriptionShutOffTime.replacingOccurrences(of: "<SHUTOFFTIME>", with: endWorkTimeString)
        
        
     //   lblDescriptionStartupTime.stringValue = descriptionStartupTime
    //    lblDescriptionShutOffTime.stringValue = descriptionShutOffTime
        
        
        
        startUpTime = Calendar.current.date(byAdding: .second, value: 0 - (morningRoutineDuration + (15*60)) , to: startTime) ?? startTime
        let shutWorkTime = Calendar.current.date(byAdding: .second, value: eveningRoutineDuration, to: shutOffTime) ?? shutOffTime
        
        let morningRoutineEndTime = Calendar.current.date(byAdding: .second, value: morningRoutineDuration , to: startUpTime) ?? startTime
        
        let morningRoutineStartTime = getStringFromDate(date: startUpTime, dateFormat: "hh:mm a")
        let endEveningRoutineTimeString = getStringFromDate(date: shutWorkTime, dateFormat: "hh:mm a")
        let morningRoutineEndTimeString = getStringFromDate(date: morningRoutineEndTime, dateFormat: "hh:mm a")
        
//        lblStartupTime.stringValue = morningRoutineStartTime
//        lblShutOfTime.stringValue = endWorkTimeString
//
        
        var explanationText = "Your schedule looks like:\n\n🐥 <MORNING_ROUTINE_START_TIME> - <MORNING_ROUTINE_END_TIME> - Morning routine\n\n💼 <MORNING_ROUTINE_END_TIME> - <START_WORK_TIME> - Prepare to start work (buffer time)\n\n💪 <START_WORK_TIME> - <END_WORK_TIME> - Work\n\n🥱 <END_WORK_TIME> - <EVENING_ROUTINE_END_TIME> - Do evening routine.\n\n😴 <EVENING_ROUTINE_END_TIME> - Finish evening routine - computer locked (you can unlock it if you need it)"
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            explanationText = askWorkTimeVcInfo.value(forKey: "explanationText") as? String ?? explanationText
        }
        
        explanationText = explanationText.replacingOccurrences(of: "<MORNING_ROUTINE_START_TIME>", with: morningRoutineStartTime)
        
        explanationText = explanationText.replacingOccurrences(of: "<MORNING_ROUTINE_END_TIME>", with: morningRoutineEndTimeString)
        
        explanationText = explanationText.replacingOccurrences(of: "<START_WORK_TIME>", with: startWorkTimeString)
        
        explanationText = explanationText.replacingOccurrences(of: "<END_WORK_TIME>", with: endWorkTimeString)
        
        explanationText = explanationText.replacingOccurrences(of: "<EVENING_ROUTINE_END_TIME>", with: endEveningRoutineTimeString)
        
        lblExplanation.stringValue = explanationText
        
        
        
        
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        let startTime = startUpTime
        let shutOffTime = getStringFromDate(date: datePickerShutDownTime.dateValue, dateFormat: "HH:mm")
        
        UserDefaults.standard.set(startTime, forKey: kUserdefaultsStartupTimeFromOnboarding)
        UserDefaults.standard.set(shutOffTime, forKey: kUserdefaultsShutOffTimeFromOnboarding)
        
        appdelegate!.showOnbardingHabit()
    }
    @IBAction func datePickerShutDownTimeClicked(_ sender: Any) {
        resetView()
    }
    
    @IBAction func datePickerStartTimeClicked(_ sender: Any) {
        resetView()
    }
}
