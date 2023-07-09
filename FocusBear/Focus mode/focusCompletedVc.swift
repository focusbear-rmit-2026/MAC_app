//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedVc: NSViewController {
    
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var textFieldDistractions: NSTextField!
    @IBOutlet weak var textFieldAchieve: NSTextField!
    @IBOutlet weak var btnStartAnotherFocusBlock: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var btnTakeBreak: Button!
    @IBOutlet weak var lblIntentionWas: NSTextField!
    @IBOutlet var textViewIntention: NSTextView!
    
    var currentFocusModeName = ""
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonTakeBreakText = "Take a 5 minute break"
    var currentFocusModeId = ""
    var finish_time:Date?
    var isShutOffTime = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnStartAnotherFocusBlock.buttonColor = NSColor.white.cgColor
        btnStartAnotherFocusBlock.title = "Start another focus block"

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
                btnStartAnotherFocusBlock.title = focusCompletedInfo.value(forKey: "buttonStartFocusText") as? String ?? btnStartAnotherFocusBlock.title
            }
        }
    }
    
    override func viewWillAppear() {
        loader.isHidden = true
        if isFocusModeStartedFromPomodoroMode{
            btnStartAnotherFocusBlock.isHidden = true
        }else{
            btnStartAnotherFocusBlock.isHidden = false
        }
    }
    
    func resetData(focusModeName:String, currentFocusModeId:String, finish_time:Date, isShutOffTime:Bool){
        self.isShutOffTime = isShutOffTime
        self.currentFocusModeName = focusModeName
        self.currentFocusModeId = currentFocusModeId
        self.finish_time = finish_time
        textFieldAchieve.stringValue = ""
        textFieldDistractions.stringValue = ""
        
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)//"You have successfully completed the focus block - \(currentFocusModeName)"
        textViewIntention.string = whatToAchieveInFocusBlock
        btnTakeBreak.isEnabled = true
        loader.isHidden = true
        if isShutOffTime{
            btnTakeBreak.title = "Continue"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                btnTakeBreak.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnTakeBreak.title
            }
            btnStartAnotherFocusBlock.isHidden = true
        }else{
            btnStartAnotherFocusBlock.isHidden = false
            btnTakeBreak.title = buttonTakeBreakText.replacingOccurrences(of: "5", with: "\(currentPomodoroBreakDuration)")
        }
    }
    
    @IBAction func btnStartAnotherFocusBlockClicked(_ sender: Any) {
        addLog(text: "focusCompletedVc - btnStartAnotherFocusBlockClicked")//
        whatToAchieveInFocusBlock = ""
        appdelegate!.setIntentionInBrainDumpWindow()
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "")

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })
        
        self.view.window?.close()
        
        startingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        startingFocusWindowControllerObj?.contentViewController = startingFocusModeVcObj
        startingFocusWindowControllerObj?.showWindow(nil)
        startingFocusModeVcObj?.startSameFocusBlockAgain()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @IBAction func btnTakeBreakClicked(_ sender: Any) {
        addLog(text: "focusCompletedVc - btnTakeBreakClicked")//
        whatToAchieveInFocusBlock = ""
        
        if !isShutOffTime{
            appdelegate!.setIntentionInBrainDumpWindow()
            if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
                if !notes.isEmpty{
                    showBrainDumpWindow()
                }
            }
            if brainDumpWcObj != nil{
                if brainDumpWcObj!.window?.isVisible ?? false{
                    brainDumpVcObj?.breakStarted()
                }
            }
        }else{
            if brainDumpWcObj != nil{
                if brainDumpWcObj!.window?.isVisible ?? false{
                    brainDumpWcObj?.window?.close()
                }
            }
            btnTakeBreak.isEnabled = false
            loader.isHidden = false
            loader.startAnimation(self)
        }
        
        
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "")

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), completionHandler: {newDic in
            DispatchQueue.main.async {
                if self.isShutOffTime{
                    mainViewControllerObj?.showFocusSummaryView()
                }
            }
        })
        
        
        let minutes = currentPomodoroWorkDuration
        let breakMinute = currentPomodoroBreakDuration
        completedPomodoroCountInHardcorePomodoro += 1
        
      
        if isFocusModeStartedFromPomodoroMode{
            if !isShutOffTime{
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
            }else{
                totalMinutesRemainingForHardcodePomodoro = 0
                isHardCorePomodoroModeOn = false
            }
            
        }
        if currentState != ._MORNING_HABIT_ && currentState != ._ACTIVITY_ && currentState != ._EVENING_HABIT_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !isShutOffTimeGoing() && !isHardCorePomodoroModeOn{
            
            let alert = NSAlert()
            alert.setSharingType()
            
            alert.messageText = "Do you want to take a full screen break?"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    alert.messageText = focusCompletedInfo.value(forKey: "alertFullScreenBreakText") as? String ?? alert.messageText
                }
            }
            
            alert.addButton(withTitle: buttonYesText)
            alert.addButton(withTitle: buttonNoText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
                if result == .alertFirstButtonReturn{
                    self.view.window?.close()
                    if lastFocusModeTempInfo != nil{
                        showaddFocusTempUrlsOrAppsWindow()
                    }
                    if currentState == ._POSTPON_MORNING_HABIT_{
                        isBreakActivityExecuteFromPostponeMorningHabit = true
                    }
                    if currentState == ._POSTPON_EVENING_HABIT_{
                        isBreakActivityExecuteFromPostponeEveningHabit = true
                    }
                    if !isMainWindowLodded{
                        mainWindowControllerObj?.loadWindow()
                    }
                    mainViewControllerObj?.executeBreakActivities()
                    shouldShowPomodoroAfterBreak = true
                }else if result == .alertSecondButtonReturn{
                    if isFocusModeStartedFromPomodoroMode{
                        appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*breakMinute))
                    }
                    showSmallTimerWindow(durationSeconds: 60*breakMinute, msg: "", isFocusBreak: true, currentTimerValue:0)
                    self.view.window?.close()
                    if lastFocusModeTempInfo != nil{
                        showaddFocusTempUrlsOrAppsWindow()
                    }
                }else{
                    self.view.window?.close()
                }
            })
            
        }else{
            if !isShutOffTime{
                if isFocusModeStartedFromPomodoroMode{
                    appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*breakMinute))
                }
                
                showSmallTimerWindow(durationSeconds: 60*breakMinute, msg: "", isFocusBreak: true, currentTimerValue:0)
                self.view.window?.close()
                if lastFocusModeTempInfo != nil{
                    showaddFocusTempUrlsOrAppsWindow()
                }
                
            }
        }
        
        
        
        
    }
    
}

///Do you want to use AI to decide if websites should be allowed?
// "We'll use Open AI to decide if the site is valid based on your current focus mode, intention, the URL, the website title and the first 100 characters of the content. This is anonymous - no identifying details are shared. "
