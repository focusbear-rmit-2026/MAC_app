//
//  askWorkTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/02/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class askWorkTimeVc: NSViewController {


    @IBOutlet weak var lblWakeUpTime: NSTextField!
    @IBOutlet weak var btnNextWakeUpTime: Button!
    @IBOutlet weak var datePickerWakeUpTime: NSDatePicker!
    @IBOutlet weak var lblQuestionWakeUpTime: NSTextField!
    @IBOutlet weak var centerYStackViewFirst: NSLayoutConstraint!
    @IBOutlet weak var topSpaceStackViewSecond: NSLayoutConstraint!
    @IBOutlet weak var stackViewSecond: NSStackView!
    @IBOutlet weak var stackViewFirst: NSStackView!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblRelaxTime: NSTextField!
    @IBOutlet weak var lblQuestionSleepTime: NSTextField!
    @IBOutlet weak var lblLockSystemTime: NSTextField!
    @IBOutlet weak var lblEveningRoutineTime: NSTextField!
    @IBOutlet weak var lblWorkTime: NSTextField!
    @IBOutlet weak var lblPrepareToWorkTime: NSTextField!
    @IBOutlet weak var lblMorningRoutineTime: NSTextField!
    @IBOutlet weak var lblQuestionFinishWorkTime: NSTextField!
    @IBOutlet weak var lblQuestionStartWorkTime: NSTextField!
    @IBOutlet weak var datePickerSleepTime: NSDatePicker!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var datePickerShutDownTime: NSDatePicker!
    @IBOutlet weak var datePickerStartTime: NSDatePicker!
    @IBOutlet weak var lblQuestion: NSTextField!

    
    @IBOutlet weak var boxWakeUpTime: NSBox!
    @IBOutlet weak var boxStartTime: NSBox!
    @IBOutlet weak var boxFinishTime: NSBox!
    @IBOutlet weak var boxSleepTime: NSBox!
    
    
    @IBOutlet weak var btnNextFinishTime: Button!
    @IBOutlet weak var btnNextStartTime: Button!
    @IBOutlet weak var btnNextSleepTime: Button!
    
    @IBOutlet weak var lblExplanation: NSTextField!
    var morningRoutineDuration: Int = 0
    var eveningRoutineDuration: Int = 0
    var startUpTime: Date = Date()
    var relaxModeTime:String = ""
    var eveningRoutineTime:String = ""
    var morningRoutineTime:String = ""
    var currentStep = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
       
        btnNextStartTime.title = "Next"
        btnNextFinishTime.title = "Next"
        btnNextSleepTime.title = "Next"
        btnNextWakeUpTime.title = "Next"
        
        lblQuestionWakeUpTime.stringValue = "What time do you usually wake up?"
        
        lblQuestionSleepTime.stringValue = "What time do you want to go to sleep?"
        lblQuestion.stringValue = "Set Startup and Shutdown time"
        btnContinue.title = "Continue"
        lblQuestion.stringValue = "When do you want to start and finish work?"
        
        lblQuestionStartWorkTime.stringValue = "What time do you start work?"
        lblQuestionFinishWorkTime.stringValue = "What time do you finish work?"

        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            lblQuestionSleepTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionSleepTimeText") as? String ?? lblQuestionSleepTime.stringValue
            lblQuestionWakeUpTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionWakeUpTimeText") as? String ?? lblQuestionWakeUpTime.stringValue
            
            if askOccupationVcObj?.isStudentSelected ?? false{
                lblQuestion.stringValue = askWorkTimeVcInfo.value(forKey: "questionText_study") as? String ?? lblQuestion.stringValue
                lblQuestionStartWorkTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionStartWorkTimeText_study") as? String ?? lblQuestionStartWorkTime.stringValue
                lblQuestionFinishWorkTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionFinishWorkTimeText_study") as? String ?? lblQuestionFinishWorkTime.stringValue
            }else{
                lblQuestion.stringValue = askWorkTimeVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
                lblQuestionStartWorkTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionStartWorkTimeText") as? String ?? lblQuestionStartWorkTime.stringValue
                lblQuestionFinishWorkTime.stringValue = askWorkTimeVcInfo.value(forKey: "questionFinishWorkTimeText") as? String ?? lblQuestionFinishWorkTime.stringValue
            }
            btnNextStartTime.title = askWorkTimeVcInfo.value(forKey: "buttonNextText") as? String ?? btnNextStartTime.title
            btnNextSleepTime.title = askWorkTimeVcInfo.value(forKey: "buttonNextText") as? String ?? btnNextSleepTime.title
            btnNextFinishTime.title = askWorkTimeVcInfo.value(forKey: "buttonNextText") as? String ?? btnNextFinishTime.title
            btnNextWakeUpTime.title = askWorkTimeVcInfo.value(forKey: "buttonNextText") as? String ?? btnNextWakeUpTime.title
        }

        morningRoutineDuration = installHabitPacksVcObj?.morningRoutineDuration ?? 0 // 
        eveningRoutineDuration = installHabitPacksVcObj?.eveningRoutineDuration ?? 0 //

        allApiObject.capturePosthog(event: "ask-work-time-shown", metadata: [:])
        
        
        datePickerStartTime.dateValue = getDateFromString(date: defaultStartTime, dateFormat: "HH:mm") ?? Date()// same time in abort button//
        datePickerShutDownTime.dateValue = getDateFromString(date: defaultShutDownTime, dateFormat: "HH:mm") ?? Date()
        datePickerSleepTime.dateValue = getDateFromString(date: defaultSleepTime, dateFormat: "HH:mm") ?? Date()
        
        let startBufferTime = Calendar.current.date(byAdding: .second, value: 0-bufferSeconds, to: datePickerStartTime.dateValue) ?? datePickerStartTime.dateValue
        let wakeUpTime = Calendar.current.date(byAdding: .second, value: 0-morningRoutineDuration, to: startBufferTime) ?? startBufferTime
        datePickerWakeUpTime.dateValue = wakeUpTime
    }
    let bufferSeconds = 900
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 7)
        showOnboardingBellIcon(view: self.view, screen: "ask-work-time-screen")
        if currentStep == 0{
            var titleSchedule = "Set your schedule"
            var infoWakeUpTimeText = "select or input the time you generally wake up each morning."
            
            if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
                titleSchedule = askWorkTimeVcInfo.value(forKey: "titleSchedule") as? String ?? titleSchedule
                infoWakeUpTimeText = askWorkTimeVcInfo.value(forKey: "infoWakeUpTimeText") as? String ?? infoWakeUpTimeText
            }
            showInformationPopover(sender: boxWakeUpTime, preferredEdge: .minX, mainTitle: titleSchedule, title: lblQuestionWakeUpTime.stringValue, description: infoWakeUpTimeText)
        }
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        NotificationCenter.default.removeObserver(self)
        hideOnboardingBellIcon(view: self.view)
    }
    
    override func viewWillAppear() {
        resetView()
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }
    @objc func viewDidResize(){
        print("viewDidResize")
        if self.view.frame.height < 675{
            stackViewFirst.spacing = 4
            stackViewSecond.spacing = 6
            let fontSize:CGFloat = 11
            lblQuestionWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionSleepTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionStartWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionFinishWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblMorningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblEveningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWorkTime.font = NSFont.boldSystemFont(ofSize: fontSize)
            lblRelaxTime.font = NSFont.systemFont(ofSize: fontSize)
            lblLockSystemTime.font = NSFont.systemFont(ofSize: fontSize)
            lblPrepareToWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblExplanation.font = NSFont.systemFont(ofSize: fontSize)
            centerYStackViewFirst.constant = -70
            topSpaceStackViewSecond.constant = 14
            lblQuestion.font = NSFont.systemFont(ofSize: 18)
        }else if self.view.frame.height < 725{
            stackViewFirst.spacing = 8
            stackViewSecond.spacing = 12
            let fontSize:CGFloat = 14
            lblQuestionWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionSleepTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionStartWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionFinishWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblMorningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblEveningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWorkTime.font = NSFont.boldSystemFont(ofSize: fontSize)
            lblRelaxTime.font = NSFont.systemFont(ofSize: fontSize)
            lblLockSystemTime.font = NSFont.systemFont(ofSize: fontSize)
            lblPrepareToWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblExplanation.font = NSFont.systemFont(ofSize: fontSize)
            centerYStackViewFirst.constant = -50
            topSpaceStackViewSecond.constant = 20
            lblQuestion.font = NSFont.systemFont(ofSize: 22)
        }else if self.view.frame.height < 920{
            stackViewFirst.spacing = 14
            stackViewSecond.spacing = 18
            let fontSize:CGFloat = 16
            lblQuestionWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionSleepTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionStartWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionFinishWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblMorningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblEveningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWorkTime.font = NSFont.boldSystemFont(ofSize: fontSize)
            lblRelaxTime.font = NSFont.systemFont(ofSize: fontSize)
            lblLockSystemTime.font = NSFont.systemFont(ofSize: fontSize)
            lblPrepareToWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblExplanation.font = NSFont.systemFont(ofSize: fontSize)
            topSpaceStackViewSecond.constant = 20
            centerYStackViewFirst.constant = -100
            lblQuestion.font = NSFont.systemFont(ofSize: 24)
        }else{
            stackViewFirst.spacing = 19
            stackViewSecond.spacing = 23
            let fontSize:CGFloat = 18
            lblQuestionWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionSleepTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionStartWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblQuestionFinishWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWakeUpTime.font = NSFont.systemFont(ofSize: fontSize)
            lblMorningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblEveningRoutineTime.font = NSFont.systemFont(ofSize: fontSize)
            lblWorkTime.font = NSFont.boldSystemFont(ofSize: fontSize)
            lblRelaxTime.font = NSFont.systemFont(ofSize: fontSize)
            lblLockSystemTime.font = NSFont.systemFont(ofSize: fontSize)
            lblPrepareToWorkTime.font = NSFont.systemFont(ofSize: fontSize)
            lblExplanation.font = NSFont.systemFont(ofSize: fontSize)
            topSpaceStackViewSecond.constant = 50
            centerYStackViewFirst.constant = -120
            lblQuestion.font = NSFont.systemFont(ofSize: 27)
        }
    }
    
    func resetView(){
        let wakeUpTime = datePickerWakeUpTime.dateValue
        let startTime = datePickerStartTime.dateValue
        let shutOffTime = datePickerShutDownTime.dateValue
        let sleepTime = datePickerSleepTime.dateValue
        
        
        let endWorkTimeString = getStringFromDate(date: datePickerShutDownTime.dateValue, dateFormat: "hh:mm a")

        
        startUpTime = wakeUpTime//Calendar.current.date(byAdding: .second, value: 0 - (morningRoutineDuration + (15*60)) , to: startTime) ?? startTime
        
        let shutWorkTime = Calendar.current.date(byAdding: .second, value: 0-1800, to: sleepTime) ?? shutOffTime
        
        let startEveningRoutineTime = Calendar.current.date(byAdding: .second, value: 0-eveningRoutineDuration, to: shutWorkTime) ?? shutOffTime
        
        let morningRoutineEndTime = Calendar.current.date(byAdding: .second, value: morningRoutineDuration , to: startUpTime) ?? startTime
       
        let bufferTime = morningRoutineEndTime.addingTimeInterval(TimeInterval(bufferSeconds))
        
        
        if bufferTime  > datePickerStartTime.dateValue{
            datePickerStartTime.dateValue = bufferTime
        }
        
            
            
        let startWorkTimeString = getStringFromDate(date: datePickerStartTime.dateValue, dateFormat: "hh:mm a")
            
        let morningRoutineStartTime = getStringFromDate(date: startUpTime, dateFormat: "hh:mm a")
        self.morningRoutineTime = morningRoutineStartTime
        let startEveningRoutineTimeString = getStringFromDate(date: startEveningRoutineTime, dateFormat: "hh:mm a")
        let endEveningRoutineTimeString = getStringFromDate(date: shutWorkTime, dateFormat: "hh:mm a")
        let morningRoutineEndTimeString = getStringFromDate(date: morningRoutineEndTime, dateFormat: "hh:mm a")
        self.eveningRoutineTime = startEveningRoutineTimeString
        self.relaxModeTime = endWorkTimeString
        var titleTimeText = "Your schedule looks like:"
        var wakeUpTimeText = "☀️ <WAKEUP_TIME> - Wake up"
        var morningRoutineTimeText = "🐥 <MORNING_ROUTINE_START_TIME> - <MORNING_ROUTINE_END_TIME> - Morning routine"
        var prepareToStartWorkTimeText = "💼 <MORNING_ROUTINE_END_TIME> - <START_WORK_TIME> - Prepare to start work (buffer time)"
        var workTimeText = "💪 <START_WORK_TIME> - <END_WORK_TIME> - Work"
        var relaxTimeText = "😌 <END_WORK_TIME> - <RELAX_END_TIME> - Free time - block nothing"
        var eveningRoutineTimeText = "🥱 <END_WORK_TIME> - <EVENING_ROUTINE_END_TIME> - Do evening routine."
        var lockComputerTimeText = "😴 <EVENING_ROUTINE_END_TIME> - Finish evening routine - computer locked (you can unlock it if you need it)"

        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            wakeUpTimeText = askWorkTimeVcInfo.value(forKey: "wakeUpTimeText") as? String ?? wakeUpTimeText
            titleTimeText = askWorkTimeVcInfo.value(forKey: "titleTimeText") as? String ?? titleTimeText
            morningRoutineTimeText = askWorkTimeVcInfo.value(forKey: "morningRoutineTimeText") as? String ?? morningRoutineTimeText
            eveningRoutineTimeText = askWorkTimeVcInfo.value(forKey: "eveningRoutineTimeText") as? String ?? eveningRoutineTimeText
            lockComputerTimeText = askWorkTimeVcInfo.value(forKey: "lockComputerTimeText") as? String ?? lockComputerTimeText
            relaxTimeText = askWorkTimeVcInfo.value(forKey: "relaxTimeText") as? String ?? relaxTimeText
            
            if askOccupationVcObj?.isStudentSelected ?? false{
                prepareToStartWorkTimeText = askWorkTimeVcInfo.value(forKey: "prepareToStartWorkTimeText_study") as? String ?? prepareToStartWorkTimeText
                workTimeText = askWorkTimeVcInfo.value(forKey: "workTimeText_study") as? String ?? workTimeText
            }else{
                prepareToStartWorkTimeText = askWorkTimeVcInfo.value(forKey: "prepareToStartWorkTimeText") as? String ?? prepareToStartWorkTimeText
                workTimeText = askWorkTimeVcInfo.value(forKey: "workTimeText") as? String ?? workTimeText
            }
        }
        wakeUpTimeText = wakeUpTimeText.replacingOccurrences(of: "<WAKEUP_TIME>", with: morningRoutineStartTime)
        morningRoutineTimeText = morningRoutineTimeText.replacingOccurrences(of: "<MORNING_ROUTINE_START_TIME>", with: morningRoutineStartTime)
        morningRoutineTimeText = morningRoutineTimeText.replacingOccurrences(of: "<MORNING_ROUTINE_END_TIME>", with: morningRoutineEndTimeString)
        prepareToStartWorkTimeText = prepareToStartWorkTimeText.replacingOccurrences(of: "<MORNING_ROUTINE_END_TIME>", with: morningRoutineEndTimeString)
        prepareToStartWorkTimeText = prepareToStartWorkTimeText.replacingOccurrences(of: "<START_WORK_TIME>", with: startWorkTimeString)
        workTimeText = workTimeText.replacingOccurrences(of: "<START_WORK_TIME>", with: startWorkTimeString)
        workTimeText = workTimeText.replacingOccurrences(of: "<END_WORK_TIME>", with: endWorkTimeString)
        
        relaxTimeText = relaxTimeText.replacingOccurrences(of: "<END_WORK_TIME>", with: endWorkTimeString)
        relaxTimeText = relaxTimeText.replacingOccurrences(of: "<RELAX_END_TIME>", with: startEveningRoutineTimeString)
        
        eveningRoutineTimeText = eveningRoutineTimeText.replacingOccurrences(of: "<END_WORK_TIME>", with: startEveningRoutineTimeString)
        eveningRoutineTimeText = eveningRoutineTimeText.replacingOccurrences(of: "<EVENING_ROUTINE_END_TIME>", with: endEveningRoutineTimeString)
        lockComputerTimeText = lockComputerTimeText.replacingOccurrences(of: "<EVENING_ROUTINE_END_TIME>", with: endEveningRoutineTimeString)

        lblWakeUpTime.stringValue = wakeUpTimeText
        lblExplanation.stringValue = titleTimeText
        lblMorningRoutineTime.stringValue = morningRoutineTimeText
        lblPrepareToWorkTime.stringValue = prepareToStartWorkTimeText
        lblWorkTime.stringValue = workTimeText
        lblEveningRoutineTime.stringValue = eveningRoutineTimeText
        lblLockSystemTime.stringValue = lockComputerTimeText
        lblRelaxTime.stringValue = relaxTimeText
        
        boxStartTime.isHidden = true
        boxFinishTime.isHidden = true
        boxSleepTime.isHidden = true
        
        btnNextWakeUpTime.isHidden = true
        btnNextStartTime.isHidden = true
        btnNextFinishTime.isHidden = true
        btnNextSleepTime.isHidden = true
        btnContinue.isEnabled = false
        stackViewSecond.isHidden = true
        
        
        if currentStep == 0{
            btnNextWakeUpTime.isHidden = false
        }else if currentStep == 1{
            boxStartTime.isHidden = false
            btnNextStartTime.isHidden = false
        }else if currentStep == 2{
            boxStartTime.isHidden = false
            boxFinishTime.isHidden = false
            btnNextFinishTime.isHidden = false
        }else if currentStep == 3{
            boxStartTime.isHidden = false
            boxFinishTime.isHidden = false
            boxSleepTime.isHidden = false
            btnNextSleepTime.isHidden = false
        }else if currentStep == 4{
            boxStartTime.isHidden = false
            boxFinishTime.isHidden = false
            boxSleepTime.isHidden = false
            btnContinue.isEnabled = true
            stackViewSecond.isHidden = false
        }
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] askWorkTimeVc:- btnContinueClicked")
        let startTime = getStringFromDate(date: startUpTime, dateFormat: "HH:mm")
        let shutOffTime = getStringFromDate(date: datePickerShutDownTime.dateValue, dateFormat: "HH:mm")
        let sleepTime = getStringFromDate(date: datePickerSleepTime.dateValue, dateFormat: "HH:mm")
        
        if sleepTime < shutOffTime{
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Sleep time cannot be less than finish work time."
            if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
                alert.messageText = askWorkTimeVcInfo.value(forKey: "sleepTimeAlertText") as? String ?? alert.messageText
            }
            
            alert.addButton(withTitle: buttonOkText)
            if let window = NSApp.keyWindow{
                alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){

                    }
                })
            }
            return;
        }
        
        UserDefaults.standard.set(startTime, forKey: kUserdefaultsStartupTimeFromOnboarding)
        UserDefaults.standard.set(shutOffTime, forKey: kUserdefaultsShutOffTimeFromOnboarding)
        UserDefaults.standard.set(sleepTime, forKey: kUserdefaultsSleepTimeFromOnboarding)
 
        
        allApiObject.capturePosthog(event: "ask-work-time-continue-clicked", metadata: [:])
        
        
        
//        if confirmMorningRoutineTimeVcObj != nil{
//            if confirmMorningRoutineTimeVcObj!.isConfirmTimeForMorningShown{
//                mainViewControllerObj!.showConfirmEveningRoutineTimeVc()
//                return;
//            }
//        }
//        mainViewControllerObj!.showConfirmMorningRoutineTimeVc()
        
        
        
//        addLog(text: "takeBreaksInfoVc:- btnContinueClicked:isBreaksEnabled:- \(isBreaksEnabled)")
//        let isBreaksEnabled = true
        UserDefaults.standard.set(20, forKey: kUserdefaultsBreakDurationValue)
        UserDefaults.standard.set(true, forKey: kUserdefaultsBreaksEnabledFromOnboarding)
        appdelegate!.showOnbardingHabit()
        
    }
    @IBAction func datePickerShutDownTimeClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "finish-time-edited", metadata: [:])
        resetView()
    }
    
    @IBAction func datePickerStartTimeClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "start-time-edited", metadata: [:])
        resetView()
    }
    @IBAction func datePickerSleepTimeClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "sleep-time-edited", metadata: [:])
        resetView()
    }
    @IBAction func datePickerWakeUpTimeClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "wakeup-time-edited", metadata: [:])
        resetView()
    }
    
    @IBAction func btnNextWakeUpTimeClicked(_ sender: Any) {
        currentStep = 1
        resetView()
        var titleSchedule = "Set your schedule"
        var infoStartTimeText = "Choose the earliest possible time you would want to start work. You’ll do your morning routine before starting work. You can start later than this time if you need to."
        
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            titleSchedule = askWorkTimeVcInfo.value(forKey: "titleSchedule") as? String ?? titleSchedule
            infoStartTimeText = askWorkTimeVcInfo.value(forKey: "infoStartTimeText") as? String ?? infoStartTimeText
        }
        showInformationPopover(sender: boxStartTime, preferredEdge: .minX, mainTitle: titleSchedule, title: lblQuestionStartWorkTime.stringValue, description: infoStartTimeText)
        
    }
    
    @IBAction func btnNextStartTimeClicked(_ sender: Any) {
        currentStep = 2
        resetView()
        var titleSchedule = "Set your schedule"
        var infoFinishTimeText = "When do you typically finish work? You can keep using your computer after this if needed but Focus Bear will nudge you to get off your tech in the evening so you can relax, do your evening routine and sleep well."
        
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            titleSchedule = askWorkTimeVcInfo.value(forKey: "titleSchedule") as? String ?? titleSchedule
            infoFinishTimeText = askWorkTimeVcInfo.value(forKey: "infoFinishTimeText") as? String ?? infoFinishTimeText
        }
        showInformationPopover(sender: boxFinishTime, preferredEdge: .minX, mainTitle: titleSchedule, title: lblQuestionFinishWorkTime.stringValue, description: infoFinishTimeText)
    }
    @IBAction func btnNextFinishTimeClicked(_ sender: Any) {
        currentStep = 3
        resetView()
        var titleSchedule = "Set your schedule"
        var infoSleepTimeText = "When do you want to get to sleep? We’ll nudge you to do your evening routine beforehand so you can wind down and sleep well."
        
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            titleSchedule = askWorkTimeVcInfo.value(forKey: "titleSchedule") as? String ?? titleSchedule
            infoSleepTimeText = askWorkTimeVcInfo.value(forKey: "infoSleepTimeText") as? String ?? infoSleepTimeText
        }
        showInformationPopover(sender: boxSleepTime, preferredEdge: .minX, mainTitle: titleSchedule, title: lblQuestionSleepTime.stringValue, description: infoSleepTimeText)
    }
    
    @IBAction func btnNextSleepTimeClicked(_ sender: Any) {
        currentStep = 4
        resetView()
    }
}
