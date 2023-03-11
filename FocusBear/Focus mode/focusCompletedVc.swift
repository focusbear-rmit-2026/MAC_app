//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedVc: NSViewController {
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet var textViewAchieve: NSTextView!
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet var textViewDistractions: NSTextView!
    @IBOutlet weak var btnTakeBreak: Button!
    @IBOutlet weak var lblIntentionWas: NSTextField!
    @IBOutlet var textViewIntention: NSTextView!
    
    var currentFocusModeName = ""
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonTakeBreakText = "Take a 5 minute break"
    var currentFocusModeId = ""
    var finish_time:Date?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        textViewIntention.isFieldEditor = true
        textViewAchieve.isFieldEditor = true
        textViewDistractions.isFieldEditor = true
        
        lblTitle.stringValue = "You did it!"
        lblQuestionFirst.stringValue = "What did you achieve during this time?"
        lblQuestionSecond.stringValue = "Any distractions?"
        lblIntentionWas.stringValue = "Your intention was"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                if let title = focusCompletedInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = focusCompletedInfo.value(forKey: "subTitle") as? String{
                    subTitleText = subTitle
                }
                if let questionFirstText = focusCompletedInfo.value(forKey: "questionFirstText") as? String{
                    lblQuestionFirst.stringValue = questionFirstText
                }
                if let questionSecondText = focusCompletedInfo.value(forKey: "questionSecondText") as? String{
                    lblQuestionSecond.stringValue = questionSecondText
                }
                if let titleIntention = focusCompletedInfo.value(forKey: "titleIntention") as? String{
                    lblIntentionWas.stringValue = titleIntention
                }
                if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonTakeBreakText") as? String{
                    self.buttonTakeBreakText = buttonTakeBreakText
                }
            }
        }
    }
    
    override func viewWillAppear() {
        
    }
    
    func resetData(focusModeName:String, currentFocusModeId:String, finish_time:Date){
        self.currentFocusModeName = focusModeName
        self.currentFocusModeId = currentFocusModeId
        self.finish_time = finish_time
        textViewAchieve.string = ""
        textViewDistractions.string = ""
        btnTakeBreak.title = buttonTakeBreakText.replacingOccurrences(of: "5", with: "\(currentPomodoroBreakDuration)")
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)//"You have successfully completed the focus block - \(currentFocusModeName)"
        textViewIntention.string = whatToAchieveInFocusBlock
    }
    
    @IBAction func btnTakeBreakClicked(_ sender: Any) {
        whatToAchieveInFocusBlock = ""
        appdelegate!.setIntensionInBrainDumpWindow()
        showBrainDumpWindow()
        brainDumpVcObj?.breakStarted()
        addLog(text: "focusCompletedVc - btnTakeBreakClicked")//
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textViewAchieve.string.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textViewDistractions.string.components(separatedBy: .newlines).joined()
        
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "")

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textViewAchieve.string, distractions: textViewDistractions.string, finish_time: self.finish_time ?? Date(), completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })
        
        
        let minutes = currentPomodoroWorkDuration
        let breakMinute = currentPomodoroBreakDuration
//        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
//            minutes = duration
//        }
        completedPomodoroCountInHardcorePomodoro += 1
        if isFocusModeStartedFromPomodoroMode{
            if isHardCorePomodoroModeOn{
                if totalMinutesRemainingForHardcodePomodoro > minutes{
                    totalMinutesRemainingForHardcodePomodoro -= minutes
                }else{
                    totalMinutesRemainingForHardcodePomodoro = 0
                }
                
                if totalMinutesRemainingForHardcodePomodoro == 0{
                    isHardCorePomodoroModeOn = false
                }
            }
            addLog(text: "pomodoro mode Finished")
            appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*breakMinute))
        }
        self.view.window?.close()
        
        showSmallTimerWindow(durationSeconds: 60*breakMinute, msg: "", isFocusBreak: true, currentTimerValue:0)
        
        if lastFocusModeTempInfo != nil{
            showaddFocusTempUrlsOrAppsWindow()
        }
    }
    
}

