//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedVc: NSViewController {
    
    @IBOutlet weak var boxTags: NSBox!
    @IBOutlet weak var btnDoBreakActivity: Button!
    @IBOutlet weak var boxTempForShowToolTip: NSBox!
    @IBOutlet weak var btnStarFirst: cursorButton!
    @IBOutlet weak var btnStarSecond: cursorButton!
    @IBOutlet weak var btnStarThird: cursorButton!
    @IBOutlet weak var btnStarFourth: cursorButton!
    @IBOutlet weak var btnStarFifth: cursorButton!
    @IBOutlet weak var btnPin: cursorButton!
    @IBOutlet weak var lblTitleTags: NSTextField!
    @IBOutlet weak var tokenFieldTags: NSTokenField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var textFieldDistractions: NSTextField!
    @IBOutlet weak var textFieldAchieve: NSTextField!
    @IBOutlet weak var btnStartAnotherFocusBlock: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var btnTakeBreak: underLineButton!
    @IBOutlet weak var lblIntentionWas: NSTextField!
    @IBOutlet var textViewIntention: NSTextView!
    
    var currentFocusModeName = ""
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonTakeBreakText = "Relax 5 minutes"
    var currentFocusModeId = ""
    var finish_time:Date?
    var isShutOffTime = false
    var arrAllTags = [String]()
    var defaultTokenMenu = NSMenu()
    var currentFocusModeIndex = 0
    
    let popoverMenuTour = NSPopover()
    var timerMoveWindowToCenter:Timer?
    
    var menuTourPopoverVcObj: menuTourPopoverVc?
    var currentIndex = 0
    var pinButtonTrackingArea: NSTrackingArea?
    var breakMinute: Int = 5
    
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    var arrTourMessages = [["title": "Intention", "description": "See what intentions have you set when starting the focus block.", "buttonTitle": "Next"],
                           ["title": "Achivements", "description": "Write a summary of what did you achieved during this focus block.", "buttonTitle": "Next"],
                           ["title": "Reporting Tags", "description": "Add reporting tags to help analyse your time logs. For example, you could add a \"billable\" tag if you're a freelancer or add tags for certain clients.", "buttonTitle": "Next"],
                           ["title": "Distractions", "description": "Did you faced any distractions? Write a summary of distractions faced.", "buttonTitle": "Finish"]]
    
    let kUserdefaultsShowTextForTokenFieldFirstTime = "kUserdefaultsShowTextForTokenFieldFirstTime"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnPin.image = #imageLiteral(resourceName: "pin")
        tokenFieldTags.delegate = self
        
        btnDoBreakActivity.title = "Do break habits"
        lblTitleTags.stringValue = "Reporting Tags"
//        btnStartAnotherFocusBlock.buttonColor = NSColor.white.cgColor
        btnStartAnotherFocusBlock.title = "Start new focus session"

        lblTitle.stringValue = "You did it!"
        lblQuestionFirst.stringValue = "What did you achieve during this time?"
        lblQuestionSecond.stringValue = "How focused were you?"
        lblIntentionWas.stringValue = "Your intention was"
        var titleTourBox = "Focus Complete Block"
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
                if let titleStarRatingText = focusCompletedInfo.value(forKey: "titleStarRatingText") as? String{
                    lblQuestionSecond.stringValue = titleStarRatingText
                }
                if let titleIntention = focusCompletedInfo.value(forKey: "titleIntention") as? String{
                    lblIntentionWas.stringValue = titleIntention
                }
                if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonRelaxText") as? String{
                    self.buttonTakeBreakText = buttonTakeBreakText
                }
                btnStartAnotherFocusBlock.title = focusCompletedInfo.value(forKey: "buttonStartFocusSessionText") as? String ?? btnStartAnotherFocusBlock.title
                btnDoBreakActivity.title = focusCompletedInfo.value(forKey: "buttonDoBreakActivitiesText") as? String ?? btnDoBreakActivity.title
                lblTitleTags.stringValue = focusCompletedInfo.value(forKey: "titleTags") as? String ?? lblTitleTags.stringValue
                arrTourMessages = focusCompletedInfo.value(forKey: "tourMessagesInfo") as? [[String:String]] ?? arrTourMessages
                titleTourBox = focusCompletedInfo.value(forKey: "titleTourBox") as? String ?? titleTourBox
            }
        }
        

        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
        }
        
        
        for i in 0..<arrTourMessages.count{
            if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusCompletedTourShown) == nil{
            menuTourPopoverVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuTourPopoverVc")) as? menuTourPopoverVc
            popoverMenuTour.contentViewController = menuTourPopoverVcObj
            popoverMenuTour.animates = false
            popoverMenuTour.behavior = .applicationDefined
            currentIndex = 0
            menuTourPopoverVcObj?.delegate = self
            menuTourPopoverVcObj?.loadView()
            menuTourPopoverVcObj?.lblMainTitle.stringValue = titleTourBox
        }
        pinButtonTrackingArea = NSTrackingArea.init(rect: btnPin.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnPin.addTrackingArea(pinButtonTrackingArea!)
        btnStartAnotherFocusBlock.buttonColor = NSColor.white.cgColor
    }
    
    override func viewWillDisappear() {
        if popoverMenuTour.isShown{
            popoverMenuTour.close()
        }
        if addTaskVcObj != nil{
            if addTaskVcObj!.presentingViewController == self{
                addTaskVcObj!.dismiss(addTaskVcObj!)
                allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-closed", metadata: [:])
            }
        }
    }
    override func viewWillAppear() {
        loader.isHidden = true
        if isHardCorePomodoroModeOn{
            btnStartAnotherFocusBlock.isHidden = true
        }else{
            btnStartAnotherFocusBlock.isHidden = false
        }
        
        if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app"){
            boxTags.isHidden = false
        }else{
            boxTags.isHidden = true
        }
        closePomodoroWindowIOfVisible()
    }
    
    override func viewDidAppear() {
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusCompletedTourShown) == nil{
            if boxTags.isHidden && arrTourMessages.count == 4{
                arrTourMessages.remove(at: 2)
            }
            popoverMenuTour.show(relativeTo:textViewIntention.bounds, of: textViewIntention, preferredEdge: NSRectEdge.minX)
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentIndex]["title"] ?? "", description: arrTourMessages[currentIndex]["description"] ?? "", buttonTitle: arrTourMessages[currentIndex]["buttonTitle"] ?? "", indexText: currentIndexText, arrList: [], progress: currentIndex + 1, progressMaxValue: arrTourMessages.count)
            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusCompletedTourShown)
        }
        
        
        if !focusModeTaskString.isEmpty{
            let obj = getAddTaskVcObject()
            obj.loadView()
            obj.reloadData(isAddingTask: false)
            self.presentAsSheet(obj)
            allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-shown", metadata: [:])
        }
        
        if self.view.window?.windowController != endingFocusWindowControllerObj{
            btnPin.isHidden = true
        }else{
            btnPin.isHidden = false
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsCompletedFocusWindowOnTop) as? Bool{
                if state{
                    btnPin.image = #imageLiteral(resourceName: "pin")
                }else{
                    btnPin.image = #imageLiteral(resourceName: "unPin")
                }
            }
        }
    }
    
    var currentRatingCount = 0
    func updateStarRatingView(){
        btnStarFirst.image = NSImage(named: "star_Gray")
        btnStarSecond.image = NSImage(named: "star_Gray")
        btnStarThird.image = NSImage(named: "star_Gray")
        btnStarFourth.image = NSImage(named: "star_Gray")
        btnStarFifth.image = NSImage(named: "star_Gray")
        
        if currentRatingCount == 1{
            btnStarFirst.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 2{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 3{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 4{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
            btnStarFourth.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 5{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
            btnStarFourth.image = NSImage(named: "star_Golden")
            btnStarFifth.image = NSImage(named: "star_Golden")
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == pinButtonTrackingArea{
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsCompletedFocusWindowOnTop) as? Bool{
                if !state{
                    
                    var pinWindowText = "You can pin this window so you don't forget to fill out your achievements after a focus session."
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                            pinWindowText = focusCompletedInfo.value(forKey: "pinWindowText") as? String ?? pinWindowText
                        }
                    }
                    showTooltip(sender: btnPin, msg: pinWindowText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
                }
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == pinButtonTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    override func viewDidDisappear() {
        if self.timerMoveWindowToCenter != nil{
            self.timerMoveWindowToCenter?.invalidate()
            self.timerMoveWindowToCenter = nil
        }
    }
    
    func resetData(focusModeName:String, currentFocusModeId:String, finish_time:Date, isShutOffTime:Bool){
        currentRatingCount = 0
        updateStarRatingView()
        arrAllTags.removeAll()
        for tagInfo in arrAllFocusModeTags{
            arrAllTags.append(tagInfo["text"] ?? "")
        }
        self.isShutOffTime = isShutOffTime
        self.currentFocusModeName = focusModeName
        self.currentFocusModeId = currentFocusModeId
        self.finish_time = finish_time
        textFieldAchieve.stringValue = ""
        textFieldDistractions.stringValue = ""
        
        
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String ?? "" == currentFocusModeId{
                currentFocusModeIndex = i
                break;
            }
        }
        
        if let tags = arrFocusType[currentFocusModeIndex]["tags"] as? [String]{
            tokenFieldTags.objectValue = tags
        }
        
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)//"You have successfully completed the focus block - \(currentFocusModeName)"
        textViewIntention.string = whatToAchieveInFocusBlock
        if !focusModeTaskString.isEmpty{
            let focusModeTaskString = getFocusModeTaskString()
            if !whatToAchieveInFocusBlock.isEmpty{
                textViewIntention.string = focusModeTaskString + "\n" + whatToAchieveInFocusBlock
            }else{
                textViewIntention.string = focusModeTaskString
            }
        }
        
        btnTakeBreak.isEnabled = true
        loader.isHidden = true
        if isShutOffTime || currentState == ._MORNING_HABIT_{
            btnTakeBreak.title = "Continue"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                btnTakeBreak.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnTakeBreak.title
            }
            btnStartAnotherFocusBlock.isHidden = true
        }else{
            if isHardCorePomodoroModeOn{
                btnStartAnotherFocusBlock.isHidden = true
            }else{
                if SettingsManagerObject.isGeekModeEnabled{
                    btnStartAnotherFocusBlock.isHidden = false
                }else{
                    btnStartAnotherFocusBlock.isHidden = true
                }
            }
            
            breakMinute = currentPomodoroBreakDuration
            if !isFocusModeStartedFromPomodoroMode{
                breakMinute = 5
            }else{
                if SettingsManagerObject.isGeekModeEnabled{
                    if pomodoroVcObj?.isBreakDurationComesFromBreakRatio ?? false {
                        var workRatio = 5
                        var breakRatio = 1
                        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro) as? Int{
                            workRatio = ratio
                        }
                        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro) as? Int{
                            breakRatio = ratio
                        }
                        
                        var breakDuration =  Int(((Double(focusModeActualDurationPerformed) / 60) / Double(workRatio)) * Double(breakRatio))
                        if breakDuration < 1{
                            breakDuration = 1
                        }
                        breakMinute = breakDuration
                    }
                }else{
                    if pomodoroVcObj?.isBreakDurationComesFromBreakRatio ?? false {
                        let workRatio = simplePomodoroVcObj?.workRatio ?? 5
                        let breakRatio = simplePomodoroVcObj?.breakRatio ?? 1
                        
                        var breakDuration =  Int(((Double(focusModeActualDurationPerformed) / 60) / Double(workRatio)) * Double(breakRatio))
                        if breakDuration < 1{
                            breakDuration = 1
                        }
                        breakMinute = breakDuration
                    }
                }
                
            }
            
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    
                    if breakMinute == 1{
                        var buttonRelaxOneMinuteText = "Relax for 1 minute"
                        if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonRelaxOneMinuteText") as? String{
                            buttonRelaxOneMinuteText = buttonTakeBreakText
                        }
                        btnTakeBreak.title = buttonRelaxOneMinuteText
                    }else{
                        if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonRelaxText") as? String{
                            self.buttonTakeBreakText = buttonTakeBreakText
                        }
                        btnTakeBreak.title = buttonTakeBreakText.replacingOccurrences(of: "5", with: "\(breakMinute)")
                    }
                }
            }
            
            
        }
        
        if currentState != ._MORNING_HABIT_ && currentState != ._ACTIVITY_ && currentState != ._EVENING_HABIT_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_EVENING_HABIT_) && arrAllbreakActivities.count != 0 && (!isShutOffTimeGoing() || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_) && !isHardCorePomodoroModeOn{
            btnDoBreakActivity.isHidden = false
        }else{
            btnDoBreakActivity.isHidden = true
        }
    }
    
    func setTimerMoveWindowToCenter(){
        if self.timerMoveWindowToCenter != nil{
            self.timerMoveWindowToCenter?.invalidate()
            self.timerMoveWindowToCenter = nil
        }
        self.timerMoveWindowToCenter = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.moveWindowToCenter), userInfo: nil, repeats: false)
    }
    @objc func moveWindowToCenter() {
        if self.view.window?.windowController == endingFocusWindowControllerObj{
            if self.view.window?.isVisible ?? false{
                self.view.window?.center()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        if self.timerMoveWindowToCenter != nil{
            self.timerMoveWindowToCenter?.invalidate()
            self.timerMoveWindowToCenter = nil
        }
    }
    
    @objc private func menuItemClicked(_ menuItem: NSMenuItem) {
        if let fieldEditor = tokenFieldTags?.currentEditor() {
            let textRange = fieldEditor.selectedRange
            let replaceString = menuItem.title
            fieldEditor.replaceCharacters(in: textRange, with: replaceString)
            fieldEditor.selectedRange = NSMakeRange(textRange.location, replaceString.count)
        }
    }
    func updateAllFocusModeTags(){
        arrAllTags.removeAll()
        updateAllFocusModes()
    }
    func getTagsString()->String{
        let tags = self.tokenFieldTags.objectValue as? [String] ?? []
        var tagsString = ""
        for i in 0..<tags.count{
            let tag = tags[i]
            if i == 0{
                tagsString += tag
            }else{
                tagsString += ";" + tag
            }
            
        }
        return tagsString
    }
    @IBAction func btnStartAnotherFocusBlockClicked(_ sender: Any) {
        addLog(text: "[user-action] focusCompletedVc - btnStartAnotherFocusBlockClicked")//
        whatToAchieveInFocusBlock = ""
        appdelegate!.setIntentionInBrainDumpWindow()
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        
        updateAllFocusModeTags()
       

        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "", tags:getTagsString())

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), rating:currentRatingCount, completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })
        
        self.view.window?.close()
        
        if currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_ || currentState == ._FOCUS_SUMMARY_{// focus end screen was showing before starting  a routine
            addLog(text: "focusCompletedVc - Start Another Focus Mode cancelled reason:- (sutofftime or morning routine time")//
            return;
        }
        appdelegate?.menuShowPomodoroModeView()
    }
    
    func workDone(){
        whatToAchieveInFocusBlock = ""
        if !isShutOffTime{
            if currentState != ._MORNING_HABIT_{
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
        
        updateAllFocusModeTags()
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "", tags:getTagsString())

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), rating:currentRatingCount, completionHandler: {newDic in
            DispatchQueue.main.async {
                if self.isShutOffTime{
                    currentState = ._NOTHING_
                    appdelegate?.shutOffMac()
                }
            }
        })
        
        
        let minutes = currentPomodoroWorkDuration
        completedPomodoroCountInHardcorePomodoro += 1
        
      
        if isFocusModeStartedFromPomodoroMode{
            if !isShutOffTime && currentState != ._MORNING_HABIT_{
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
        
        if isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
            if mainViewControllerObj?.breakTimer != nil{
                mainViewControllerObj?.setActivityTimer()
            }
        }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
            if mainViewControllerObj?.breakTimer != nil{
                mainViewControllerObj?.setActivityTimer()
            }
        }else if startingFocusModeVcObj?.lastSkipMicroBreakState ?? false{
            if mainViewControllerObj?.breakTimer != nil{
                mainViewControllerObj?.setActivityTimer()
            }
        }
    }
    @IBAction func btnDoBreakActivityClicked(_ sender: Any) {
        addLog(text: "[user-action] focusCompletedVc - btnDoBreakActivityClicked")
        workDone()
        
        self.view.window?.close()
        if lastFocusModeTempInfo != nil{
            showaddFocusTempUrlsOrAppsWindow()
        }
        if currentState == ._POSTPON_MORNING_HABIT_{
            isBreakActivityExecuteFromPostponeMorningHabit = true
        }
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            isBreakActivityExecuteFromPostponeEveningHabit = true
        }
        if !isMainWindowLoaded{
            mainWindowControllerObj?.loadWindow()
        }
        mainViewControllerObj?.executeBreakActivities()
        shouldShowPomodoroAfterBreak = true
        shouldEndPomodoroBreakAtTime = Date().addingTimeInterval(TimeInterval(60*self.breakMinute))
    }
    @IBAction func btnTakeBreakClicked(_ sender: Any) {
        addLog(text: "[user-action] focusCompletedVc - btnRelaxClicked")//
        workDone()
        
        if currentState != ._MORNING_HABIT_ && currentState != ._ACTIVITY_ && currentState != ._EVENING_HABIT_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !isShutOffTimeGoing() && !isHardCorePomodoroModeOn{
            
            appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*self.breakMinute))
            if isAppEnable{
                isFocusBreakOn = true
            }
            showSmallTimerWindow(durationSeconds: 60*self.breakMinute, msg: "", isFocusBreak: true, currentTimerValue:0)
            self.view.window?.close()
            if lastFocusModeTempInfo != nil{
                showaddFocusTempUrlsOrAppsWindow()
            }
            
        }else{
            var shouldShowAlert = false
            if isHardCorePomodoroModeOn{
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                    if state{
                        if UserDefaults.standard.object(forKey: kUserdefaultsSitesUnlockedInPomodoroBreakAlertShown) == nil{
                            UserDefaults.standard.set(true, forKey: kUserdefaultsSitesUnlockedInPomodoroBreakAlertShown)
                            shouldShowAlert = true
                        }
                    }
                }
            }
            
            if shouldShowAlert{
                let alert = NSAlert()
                alert.setSharingType()
                
                var alertBlockUrlsDisbaledInBreaksText = "Super distracting sites unlocked during your pomodoro break. If you're brave, you can keep distractions blocked and go for a walk away from your computer instead."
                var buttonBlockUrlsText = "Block distractions!"
                var buttonCancelText = "Let me get distracted 😅"
                
                
                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                    if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                        alertBlockUrlsDisbaledInBreaksText = focusCompletedInfo.value(forKey: "alertBlockUrlsDisbaledInBreaksText") as? String ?? alertBlockUrlsDisbaledInBreaksText
                        buttonBlockUrlsText = focusCompletedInfo.value(forKey: "buttonBlockUrlsText") as? String ?? buttonBlockUrlsText
                        buttonCancelText = focusCompletedInfo.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
                    }
                }
                
                alert.messageText = alertBlockUrlsDisbaledInBreaksText
                alert.addButton(withTitle: buttonBlockUrlsText)
                alert.addButton(withTitle: buttonCancelText)
                NSApplication.shared.activate(ignoringOtherApps: true)
                alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
                    if result == .alertFirstButtonReturn{
                        print("Block distractions!")
                        SettingsManagerObject.isSettingsChanged = true
                        UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
                        SettingsManagerObject.putUserLocalDeviceSettings()
                    }
                    windowClose()
                })
                
            }else{
                windowClose()
            }
            
            
            func windowClose(){
                if currentState == ._MORNING_HABIT_{
                    if self == focusCompletedVcObj{//normal case
                        self.view.window?.close()// focus end screen was showing before starting  a routine
                    }else{
                        if brainDumpWcObj != nil{
                            if brainDumpWcObj!.window?.isVisible ?? false{
                                brainDumpWcObj?.window?.close()
                            }
                        }
                        currentState = ._NOTHING_
                        btnTakeBreak.isEnabled = false
                        loader.isHidden = false
                        loader.startAnimation(self)
                        appdelegate!.backgroundThread()
                    }
                    
                }else if !isShutOffTime && currentState != ._MORNING_HABIT_{
                    if currentState == ._FOCUS_SUMMARY_ || currentState == ._EVENING_HABIT_{// focus end screen was showing before starting  a routine or before shutOff time
                        self.view.window?.close()
                    }else{
                        if isFocusModeStartedFromPomodoroMode{
                            appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*breakMinute))
                            if isAppEnable{
                                isFocusBreakOn = true
                            }
                        }
                        if isHardCorePomodoroModeOn && UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool == true{
                            showSavedSitesForLaterWindowForBreaks()
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
    }
    
    @IBAction func btnPinClicked(_ sender: Any) {
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsCompletedFocusWindowOnTop) as? Bool{
            if state{
                UserDefaults.standard.set(false, forKey: kUserdefaultsIsCompletedFocusWindowOnTop)
                self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
                btnPin.image = #imageLiteral(resourceName: "unPin")
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsCompletedFocusWindowOnTop)
                self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
                btnPin.image = #imageLiteral(resourceName: "pin")
            }
        }
    }

    
    
    @IBAction func btnStarFirstClicked(_ sender: Any) {
        currentRatingCount = 1
        updateStarRatingView()
    }
    
    @IBAction func btnStarSecondClicked(_ sender: Any) {
        currentRatingCount = 2
        updateStarRatingView()
    }
    
    @IBAction func btnStarThirdClicked(_ sender: Any) {
        currentRatingCount = 3
        updateStarRatingView()
    }
    
    @IBAction func btnStarFourthClicked(_ sender: Any) {
        currentRatingCount = 4
        updateStarRatingView()
    }
    
    @IBAction func btnStarFifthClicked(_ sender: Any) {
        currentRatingCount = 5
        updateStarRatingView()
    }
    
    
    
}



extension focusCompletedVc:NSTextFieldDelegate, NSTokenFieldDelegate{
    
    func controlTextDidChange(_ obj: Notification) {
        if let tokenFieldTags = obj.object as? NSTokenField{
            if tokenFieldTags == self.tokenFieldTags{
                let selectedRow = currentFocusModeIndex
                var dic = arrFocusType[selectedRow]
                dic["tags"] = self.tokenFieldTags.objectValue as? [String] ?? []

                arrFocusType[selectedRow] = dic
            }
        }
    }
    func controlTextDidBeginEditing(_ obj: Notification) {
        if let tokenFieldTags = obj.object as? NSTokenField{
            if UserDefaults.standard.object(forKey: kUserdefaultsShowTextForTokenFieldFirstTime) == nil{
                if tokenFieldTags == self.tokenFieldTags{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsShowTextForTokenFieldFirstTime)
                    var addTagsInfoText = "Press enter to add the tag"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                            addTagsInfoText = focusCompletedInfo.value(forKey: "addTagsInfoText") as? String ?? addTagsInfoText
                        }
                    }
                    
                    showTooltip(sender: self.boxTempForShowToolTip, msg: addTagsInfoText, preferredEdge: .maxY, maxWidthVal: 250)
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                        popoverTooltip?.close()
                    }
                }
            }
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return true
    }
    func tokenField(_ tokenField: NSTokenField,
                    menuForRepresentedObject representedObject: Any) -> NSMenu? {
        defaultTokenMenu.removeAllItems()
        for habit in arrAllTags{//
            let item = NSMenuItem(title: habit, action: #selector(menuItemClicked), keyEquivalent: "")
            item.target = self
            defaultTokenMenu.addItem(item)
        }
        
        return defaultTokenMenu
    }
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        return arrAllTags.filter { $0.lowercased().hasPrefix(substring.lowercased()) }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {

        DispatchQueue.global().async {
            DispatchQueue.main.async {
                
                let selectedRow = self.currentFocusModeIndex
                var dic = arrFocusType[selectedRow]
                //dic["tags"] = self.tokenField.objectValue as? [String] ?? []
                let tags = self.tokenFieldTags.objectValue as? [String] ?? []
                
                var finalTags = [String]()
                for i in 0..<tags.count{
                    if !finalTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                        finalTags.append(tags[i])
                        if !self.arrAllTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                            self.arrAllTags.append(tags[i])
                        }
                    }
                }
                dic["tags"] = finalTags
                arrFocusType[selectedRow] = dic
                self.tokenFieldTags.objectValue = finalTags
            }
        }
        return tokens
    }
    
}

extension focusCompletedVc: TourDelegate{
    func buttonNextClicked() {
        currentIndex += 1
        if currentIndex == 1{
            popoverMenuTour.show(relativeTo: textFieldAchieve.bounds, of: textFieldAchieve, preferredEdge: NSRectEdge.minX)
        }else if currentIndex == 2{
            if boxTags.isHidden{
                popoverMenuTour.show(relativeTo: textFieldDistractions.bounds, of: textFieldDistractions, preferredEdge: NSRectEdge.minX)
            }else{
                popoverMenuTour.show(relativeTo: tokenFieldTags.bounds, of: tokenFieldTags, preferredEdge: NSRectEdge.minX)
            }
            
        }else if currentIndex == 3{
            popoverMenuTour.show(relativeTo: textFieldDistractions.bounds, of: textFieldDistractions, preferredEdge: NSRectEdge.minX)
        }
        if currentIndex < arrTourMessages.count{
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentIndex]["title"] ?? "", description: arrTourMessages[currentIndex]["description"] ?? "", buttonTitle: arrTourMessages[currentIndex]["buttonTitle"] ?? "", indexText: currentIndexText, arrList: [], progress: currentIndex + 1, progressMaxValue: arrTourMessages.count)
        }else{
            popoverMenuTour.close()
        }
    }
    func buttonCloseClicked() {
        popoverMenuTour.close()
    }
}
