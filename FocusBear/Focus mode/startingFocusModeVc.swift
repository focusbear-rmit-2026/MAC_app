//
//  startingFocusModeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class startingFocusModeVc: NSViewController, NSTextFieldDelegate { // not in use

    @IBOutlet weak var lblTitleStrictnessLevel: NSTextField!
    @IBOutlet weak var btnStrictnessNormal: hoverInfoButton!
    @IBOutlet weak var btnStrictnessSuperStrict: hoverInfoButton!
    @IBOutlet weak var btnStrictnessStrict: hoverInfoButton!
    @IBOutlet weak var lblStrictnessNormal: NSTextField!
    @IBOutlet weak var lblStrictnessStrict: NSTextField!
    @IBOutlet weak var lblStrictnessSuperStrict: NSTextField!
    
    @IBOutlet weak var sliderStrictness: CustomSlider!
    @IBOutlet weak var heightBtnStartFocus: NSLayoutConstraint!
//    @IBOutlet weak var heightBtnChooseTask: NSLayoutConstraint!
    @IBOutlet weak var stackViewBottom: NSStackView!
    @IBOutlet weak var heightTextView: NSLayoutConstraint!
    @IBOutlet weak var topSpaceTitle: NSLayoutConstraint!
    @IBOutlet weak var boxNewBadge: customNewBadgeBox!
    @IBOutlet weak var popUpBtnFocusAlignmentScore: NSPopUpButton!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var stackViewFocusAlignmentScore: NSStackView!
//    @IBOutlet weak var btnFrictionLevelInfo: hoverInfoButton!
//    @IBOutlet weak var lblFrictionLevel: NSTextField!
//    @IBOutlet weak var lblTitleFrictionLevel: NSTextField!
    @IBOutlet weak var lblTimeFocused: NSTextField!
//    @IBOutlet weak var lblTitleSelectedTasks: NSTextField!
//    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var stackViewQuestion: NSStackView!
//    @IBOutlet weak var boxEmptySpace: NSBox!
//    @IBOutlet weak var btnWriteIntention: underLineButton!
//    @IBOutlet weak var btnChooseTask: Button!
    @IBOutlet weak var btnSettings: underLineButton!
    @IBOutlet weak var btnInfo: cursorButton!
    @IBOutlet weak var checkBoxSkipMicrobreaks: NSButton!
    @IBOutlet weak var lblTimerUnfocused: NSTextField!
    @IBOutlet weak var lblExplanation: NSTextField!
    @IBOutlet weak var lblLockedFocusDescription: NSTextField!
    @IBOutlet weak var lblMinute: NSTextField!
    @IBOutlet weak var lblHour: NSTextField!
    @IBOutlet weak var textFieldMinutesValue: NSTextField!
    @IBOutlet weak var textFieldHourValue: NSTextField!
    @IBOutlet weak var lblHowMuchTime: NSTextField!
    @IBOutlet weak var btnStartFocus: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet var textViewQuestion: NSTextView!
    @IBOutlet weak var checkBoxShowTimer: NSButton!
    @IBOutlet weak var checkBoxSaveIntention: NSButton!
    
    var focusIndex = 0
    var focusType = ""
    var titleText = "Starting Focus type - <FOCUSTYPE>"
    var timerText = "Time spend unfocused: <TIME>"
    var lastFocusModeId = ""
    var lastIntention = ""
    var lastHourValue = 0
    var lastMinuteValue = 0
    var lastSkipMicroBreakState = false
    let kUserdefaultsLastFocusModeHourDuration = "kUserdefaultsLastFocusModeHourDuration"
    let kUserdefaultsLastFocusModeMinuteDuration = "kUserdefaultsLastFocusModeMinuteDuration"
//    var arrTask = [[String : Any]]()
    var arrTourMessages: [[String : String]] = []
    var currentTourIndex = 0
    
//    var addTaskVcObj:addTaskVc!// = getAddTaskVcObject()
    var alertExtendPostpone: NSAlert?
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc // only for cutOffTime in hardskip
//    let popoverMenuTour = NSPopover()
//    var menuTourPopoverVcObj: menuTourPopoverVc?
    
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        focusModeStartWindowLodded = true

        arrTourMessages.removeAll()
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        lblStrictnessNormal.stringValue = "Normal"
        lblStrictnessStrict.stringValue = "Strict"
        lblStrictnessSuperStrict.stringValue = "Super strict"
        
        
        var tourSelectTasks = "Select tasks"
        var descriptionSelectTasks = "Choose tasks to focus on from Focus Bear's inbuilt to do list"
        var tourIntention = "Freeform intention"
        var descriptionIntention = "If you don't want to bother creating tasks, you can write a quick intention for what you'll do during this focus session"
        
        
        
        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        
        lblFocusAlignmentScore.stringValue = "Show distracting site popup only when focus alignment score is less than"
//        lblFrictionLevel.stringValue = "low"
//        lblTitleFrictionLevel.stringValue = "Friction level:"
//        lblTitleSelectedTasks.stringValue = "Selected Tasks:"
//        btnWriteIntention.title = "Write a freeform intention instead"
//        btnChooseTask.title = "Choose task to work on"
        checkBoxSaveIntention.title = "Save intention as template"
        btnSettings.title = "Settings"
        
        checkBoxShowTimer.title = "Show timer in menu bar when running a Focus Block"
        btnStartFocus.title = "Start Focus"
        lblHowMuchTime.stringValue = "How much time to focus for:"
        lblHour.stringValue = "hours"
        lblMinute.stringValue = "minutes"
        textFieldMinutesValue.delegate = self
        textFieldHourValue.delegate = self
        lblQuestion.stringValue = "What do you plan to achieve during this focus block?"
        
        lblLockedFocusDescription.stringValue = "You'll only be able to use {URL} in {APP}"
        
        lblExplanation.stringValue = "Setting an intention for the focus block helps prime your brain to accomplish that task. To edit the intention after starting the focus mode, click Brain Dump in the menu bar."
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                if let title = startingFocusModeInfo.value(forKey: "title") as? String{
                    titleText = title
                }
                if let questionText = startingFocusModeInfo.value(forKey: "questionText") as? String{
                    lblQuestion.stringValue = questionText
                }
                if let buttonStartFocusText = startingFocusModeInfo.value(forKey: "buttonStartFocusText") as? String{
                    btnStartFocus.title = buttonStartFocusText
                }
                if let howMuchTimeText = startingFocusModeInfo.value(forKey: "howMuchTimeText") as? String{
                    lblHowMuchTime.stringValue = howMuchTimeText
                }
                if let hoursText = startingFocusModeInfo.value(forKey: "hoursText") as? String{
                    lblHour.stringValue = hoursText
                }
                if let minutesText = startingFocusModeInfo.value(forKey: "minutesText") as? String{
                    lblMinute.stringValue = minutesText
                }
                lblExplanation.stringValue = startingFocusModeInfo.value(forKey: "explanationText") as? String ?? lblExplanation.stringValue
                checkBoxShowTimer.title = startingFocusModeInfo.value(forKey: "buttonShowTimerInMenuText") as? String ?? checkBoxShowTimer.title
                btnSettings.title = startingFocusModeInfo.value(forKey: "buttonSettingsText") as? String ?? btnSettings.title
                checkBoxSaveIntention.title = startingFocusModeInfo.value(forKey: "buttonSaveIntentionText") as? String ?? checkBoxSaveIntention.title
                
//                btnWriteIntention.title = startingFocusModeInfo.value(forKey: "buttonWriteIntentionText") as? String ?? btnWriteIntention.title
//                btnChooseTask.title = startingFocusModeInfo.value(forKey: "buttonChooseTaskText") as? String ?? btnChooseTask.title
//                lblTitleSelectedTasks.stringValue = startingFocusModeInfo.value(forKey: "selectedTasksText") as? String ?? lblTitleSelectedTasks.stringValue
//                lblFrictionLevel.stringValue = startingFocusModeInfo.value(forKey: "frictionLevelLowText") as? String ?? lblFrictionLevel.stringValue
//                lblTitleFrictionLevel.stringValue = startingFocusModeInfo.value(forKey: "titleFrictionLevel") as? String ?? lblTitleFrictionLevel.stringValue
                
                lblStrictnessNormal.stringValue = startingFocusModeInfo.value(forKey: "strictnessNormalText") as? String ?? lblStrictnessNormal.stringValue
                lblStrictnessStrict.stringValue = startingFocusModeInfo.value(forKey: "strictnessStrictText") as? String ?? lblStrictnessStrict.stringValue
                lblStrictnessSuperStrict.stringValue = startingFocusModeInfo.value(forKey: "strictnessSuperStrictText") as? String ?? lblStrictnessSuperStrict.stringValue
                lblTitleStrictnessLevel.stringValue = startingFocusModeInfo.value(forKey: "titleStrictnessLevel") as? String ?? lblTitleStrictnessLevel.stringValue
            }
        }
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            lblFocusAlignmentScore.stringValue = focusPreferencesAdvancedInfo.value(forKey: "focusAlignmentScoreTitle") as? String ?? lblFocusAlignmentScore.stringValue
        }
        
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            timerText = pomodoroInfo.value(forKey: "timerText") as? String ?? timerText
            tourSelectTasks = pomodoroInfo.value(forKey: "tourSelectTasks") as? String ?? tourSelectTasks
            descriptionSelectTasks = pomodoroInfo.value(forKey: "descriptionSelectTasks") as? String ?? descriptionSelectTasks
            tourIntention = pomodoroInfo.value(forKey: "tourIntention") as? String ?? tourIntention
            descriptionIntention = pomodoroInfo.value(forKey: "descriptionIntention") as? String ?? descriptionIntention
        }
        
        arrTourMessages.append(["title": tourSelectTasks, "description": descriptionSelectTasks])
        arrTourMessages.append(["title": tourIntention, "description": descriptionIntention])
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
        }
        
        checkBoxSkipMicrobreaks.title = "Skip microbreaks during work blocks?"
        
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            checkBoxSkipMicrobreaks.title = pomodoroInfo.value(forKey: "buttonSkipMicrobreaksText") as? String ?? checkBoxSkipMicrobreaks.title
        }
 
        popUpBtnFocusAlignmentScore.removeAllItems()
        popUpBtnFocusAlignmentScore.addItems(withTitles: arrFocusAlignmentScore)
        
        
        
        for i in 0..<arrTourMessages.count{
            if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }
        boxNewBadge.isHidden = true
    }

    override func viewWillAppear() {
        btnSettings.isHidden = false
        checkBoxSkipMicrobreaks.isHidden = true
        checkBoxShowTimer.isHidden = true
        checkBoxSaveIntention.isHidden = true
        stackViewFocusAlignmentScore.isHidden = true
//        addTaskVcObj = getAddTaskVcObject()
//        if !addTaskVcObj.isViewLoaded{
//            addTaskVcObj.loadView()
//        }
//        addTaskVcObj.reloadData(isAddingTask: true)
        viewDidResize()
    }
    override func viewWillDisappear() {
        timer?.invalidate()
        timer = nil
//        addTaskVcObj.isAddingTask = false
//        addTaskVcObj.isWebViewUrlLodded = false
//        if addTaskVcObj.presentingViewController == self{
//            addTaskVcObj.dismiss(addTaskVcObj)
//        }
        if alertExtendPostpone != nil{
            if alertExtendPostpone!.window.isVisible{
                self.view.window!.endSheet(alertExtendPostpone!.window)
            }
        }
        if enterPasswordVcObj != nil{
            if self == enterPasswordVcObj!.presentingViewController{
                enterPasswordVcObj!.dismiss(enterPasswordVcObj!)
            }
        }
    }
    

    @objc func viewDidResize(){
        print("viewDidResize")
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        
        if screenFrame.height < 900{
            let fontSizeNinteen:CGFloat = 19
            var fontSizefourteen:CGFloat = 14
            var fontSizeSixteen:CGFloat = 16
            var fontSizeThirteen:CGFloat = 13
            
            if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
                fontSizeThirteen = 11
                fontSizefourteen = 12
                fontSizeSixteen = 13
                
//                heightBtnChooseTask.constant = 26
                heightBtnStartFocus.constant = 34
                stackViewBottom.spacing = 4
                topSpaceTitle.constant = 15
            }else{
//                heightBtnChooseTask.constant = 26
                heightBtnStartFocus.constant = 34
                stackViewBottom.spacing = 6
                topSpaceTitle.constant = 20
            }
            lblTitle.font =  getRegularFont(size: fontSizeNinteen)
            lblFocusAlignmentScore.font =  getRegularFont(size: fontSizeThirteen)
            checkBoxSaveIntention.font =  getRegularFont(size: fontSizeThirteen)
            checkBoxShowTimer.font =  getRegularFont(size: fontSizeThirteen)
            checkBoxSkipMicrobreaks.font =  getRegularFont(size: fontSizeThirteen)
            lblExplanation.font =  getRegularFont(size: fontSizeThirteen)
            popUpBtnFocusAlignmentScore.font =  getRegularFont(size: fontSizeThirteen)
            lblTimeFocused.font =  getRegularFont(size: fontSizeThirteen)
            lblTimerUnfocused.font =  getRegularFont(size: fontSizeThirteen)
            lblLockedFocusDescription.font =  getRegularFont(size: fontSizefourteen)
            lblHowMuchTime.font =  getRegularFont(size: fontSizefourteen)
            lblHour.font =  getRegularFont(size: fontSizefourteen)
            lblMinute.font =  getRegularFont(size: fontSizefourteen)
            textFieldHourValue.font =  getRegularFont(size: fontSizeThirteen)
            textFieldMinutesValue.font =  getRegularFont(size: fontSizeThirteen)
//            lblTitleSelectedTasks.font =  getRegularFont(size: fontSizeThirteen)
            lblQuestion.font =  getRegularFont(size: fontSizefourteen)
//            btnChooseTask.font =  getRegularFont(size: fontSizefourteen)
//            btnWriteIntention.font =  getRegularFont(size: fontSizefourteen)
            btnStartFocus.font =  getRegularFont(size: fontSizeSixteen)
            lblTitleStrictnessLevel.font =  getRegularFont(size: fontSizeThirteen)
            lblStrictnessNormal.font =  getRegularFont(size: fontSizeThirteen)
            lblStrictnessStrict.font =  getRegularFont(size: fontSizeThirteen)
            lblStrictnessSuperStrict.font =  getRegularFont(size: fontSizeThirteen)
            
        }else{
            lblTitle.font =  getRegularFont(size: 25)
            lblFocusAlignmentScore.font =  getRegularFont(size: 14)
            checkBoxSaveIntention.font =  getRegularFont(size: 14)
            checkBoxShowTimer.font =  getRegularFont(size: 14)
            checkBoxSkipMicrobreaks.font =  getRegularFont(size: 14)
            lblExplanation.font =  getRegularFont(size: 14)
            popUpBtnFocusAlignmentScore.font =  getRegularFont(size: 13)
            lblTimeFocused.font =  getRegularFont(size: 14)
            lblTimerUnfocused.font =  getRegularFont(size: 14)
            lblLockedFocusDescription.font =  getRegularFont(size: 15)
            lblHowMuchTime.font =  getRegularFont(size: 15)
            lblHour.font =  getRegularFont(size: 15)
            lblMinute.font =  getRegularFont(size: 15)
            textFieldHourValue.font =  getRegularFont(size: 14)
            textFieldMinutesValue.font =  getRegularFont(size: 14)
//            lblTitleSelectedTasks.font =  getRegularFont(size: 14)
            lblQuestion.font =  getRegularFont(size: 15)
//            btnChooseTask.font =  getRegularFont(size: 15)
//            btnWriteIntention.font =  getRegularFont(size: 15)
            btnStartFocus.font =  getRegularFont(size: 20)
            heightBtnStartFocus.constant = 40
//            heightBtnChooseTask.constant = 30
            stackViewBottom.spacing = 10
            topSpaceTitle.constant = 30
            lblTitleStrictnessLevel.font =  getRegularFont(size: 14)
            lblStrictnessNormal.font =  getRegularFont(size: 14)
            lblStrictnessStrict.font =  getRegularFont(size: 14)
            lblStrictnessSuperStrict.font =  getRegularFont(size: 14)
        }
    }
    
//    @IBAction func btnWriteIntentionClicked(_ sender: Any) {
//        btnInfo.isHidden = false
//        lblExplanation.isHidden = true
//        textViewQuestion.enclosingScrollView?.isHidden = false
//        lblQuestion.isHidden = false
////        boxEmptySpace.isHidden = true
//        stackViewQuestion.isHidden = false
//    }
//    @IBAction func btnChooseTaskClicked(_ sender: Any) {
//        textViewQuestion.string = ""
//        btnInfo.isHidden = true
//        lblExplanation.isHidden = true
//        textViewQuestion.enclosingScrollView?.isHidden = true
//        lblQuestion.isHidden = true
////        boxEmptySpace.isHidden = false
//        stackViewQuestion.isHidden = true
//
//        addTaskVcObj.reloadData(isAddingTask: true)
//        self.presentAsSheet(addTaskVcObj)
//    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        btnInfo.isHidden = true
        lblExplanation.isHidden = false
    }
    @IBAction func btnSettingsClicked(_ sender: Any) {
        btnSettings.isHidden = true
        checkBoxSkipMicrobreaks.isHidden = false
        checkBoxShowTimer.isHidden = false
        checkBoxSaveIntention.isHidden = false
        if SettingsManagerObject.isCuddlyModeEnabled && SettingsManagerObject.isAiCheckUrlEnabled{
            stackViewFocusAlignmentScore.isHidden = false
        }
    }
    var timer:Timer?
    var currentTimer = 0
    func startTimer() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }

        currentTimer = unfocusedTime
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }

        self.lblTimerUnfocused.stringValue = timerText.replacingOccurrences(of: "<TIME>", with: "\(hour):\(minute):\(second)")
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func setProgres(){
        let remainingSeconds = currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"

        if hour.count == 1 {
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblTimerUnfocused.stringValue = self.timerText.replacingOccurrences(of: "<TIME>", with: "\(hour):\(minute):\(second)")//"Time spend unfocused: \(hour):\(minute):\(second)"//
        }
    }
    @objc func performTimerCount() {
        if !appdelegate!.isSystemSleep && !appdelegate!.isScreenSaverStart && currentState != ._ACTIVITY_{
            currentTimer += 1
        }
        setProgres()
    }
    
    func startFocusMode(){
        if sliderStrictness.integerValue == 1{
            currentFocusModeStrictness = ._NORMAL_
        }else if sliderStrictness.integerValue == 2{
            currentFocusModeStrictness = ._STRICT_
        }else if sliderStrictness.integerValue == 3{
            currentFocusModeStrictness = ._SUPER_STRICT_
        }
        UserDefaults.standard.set(sliderStrictness.integerValue, forKey: kUserdefaultsLastFocusModeStrictness)
        if getEndFocusModeWindowControllerObj().window!.isVisible{
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            getEndFocusModeWindowControllerObj().window?.close()
        }
        
        if checkBoxSkipMicrobreaks.state == .on{
            isSkipBreakActivityDuringFocus = true
        }else{
            isSkipBreakActivityDuringFocus = false
        }
        
        if checkBoxShowTimer.state == .on{
            isShowTimerInFocusEnabled = true
        }else{
            isShowTimerInFocusEnabled = false
        }
        if checkBoxSaveIntention.state == .on{
            if textViewQuestion.string.isEmpty{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastFocusSavedIntention)
            }else{
                UserDefaults.standard.set(textViewQuestion.string, forKey: kUserdefaultsLastFocusSavedIntention)
            }
        }else{
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastFocusSavedIntention)
        }
        
        
        let calendar = Calendar.current
        let totoalMinutes = (textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
        endFocusModeTime = calendar.date(byAdding: .minute, value: totoalMinutes, to: Date())
        startFocusModeTime = Date()
        arrFocusType[focusIndex]["isOn"] = true
        shouldReloadTaskPlayer = true
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        UserDefaults.standard.set(textFieldHourValue.integerValue, forKey: kUserdefaultsLastFocusModeHourDuration)
        UserDefaults.standard.set(textFieldMinutesValue.integerValue, forKey: kUserdefaultsLastFocusModeMinuteDuration)
        
        let oldFocusAlignmentScoreThreshold = arrFocusType[focusIndex]["focusAlignmentScoreThreshold"] as? Int ?? -1
        let focusAlignmentScoreThreshold = Int(popUpBtnFocusAlignmentScore.titleOfSelectedItem ?? "") ?? 80
        if oldFocusAlignmentScoreThreshold != focusAlignmentScoreThreshold{
            arrFocusType[focusIndex]["focusAlignmentScoreThreshold"] = focusAlignmentScoreThreshold
            allApiObject.capturePosthog(event: "focus-alignment-score-threshold-changed", metadata: [:])
        }
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            focusModeTaskString = arrFocusType[focusIndex]["lastTaskUsed"] as? String ?? ""
            showTaskPlayerWindow(totalDuration: totoalMinutes, intention: textViewQuestion.string, automatically:true)
        }else{
            focusModeTaskString = ""
        }
        if !textViewQuestion.string.isEmpty{
            arrFocusType[focusIndex]["lastIntentionUsed"] = textViewQuestion.string
        }else{
            arrFocusType[focusIndex]["lastIntentionUsed"] = ""
        }
        
        updateAllFocusModes()
        if let isAutoDoNotDisturbEnabled = arrFocusType[focusIndex]["isAutoDoNotDisturbEnabled"] as? Bool{
            if isAutoDoNotDisturbEnabled{
                if isAccessibilityEnabled(isPrompt: true){
                    enableDND()
                }
            }
        }
        if !isDndEnabled{
            if let isDeepWorkFocus = arrFocusType[focusIndex]["isDeepWorkFocus"] as? Bool{
                if  isDeepWorkFocus{
                    if isAccessibilityEnabled(isPrompt: true){
                        enableDND()
                    }
                }
            }else if let isDefault = arrFocusType[focusIndex]["isDefault"] as? Bool{
                if  isDefault{
                    if isAccessibilityEnabled(isPrompt: true){
                        enableDND()
                    }
                }
            }
        }
        
        workBeforeFocusBegin(index: focusIndex)
        minFocusAlignmentScoreToShowDistractingPopUp = Double(popUpBtnFocusAlignmentScore.title) ?? 80
        if SettingsManagerObject.isDataCollectionModeEnabled{
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }
        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusType[focusIndex]["color"] as? String ?? "")
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: textViewQuestion.string)
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        isFocusTimeType = ._HOUR_
        appdelegate?.setFocusModeTimer(hour: nil, minute: totoalMinutes)
        isFocusModeStartedFromPomodoroMode = false
        closePomodoroWindowIOfVisible()
        whatToAchieveInFocusBlock = textViewQuestion.string
        appdelegate!.focusModeStartted(isStartedByPusher: false)
        isFocusModeStartedAutomatically = false
        if arrFocusType[focusIndex]["isLockedFocus"] as? Bool == true{
            allApiObject.capturePosthog(event: "start-lock-in-current-focus", metadata: [:])
        }
        
        lastIntention = textViewQuestion.string
        lastHourValue = textFieldHourValue.integerValue
        lastMinuteValue = textFieldMinutesValue.integerValue
        lastSkipMicroBreakState = isSkipBreakActivityDuringFocus
        
        allApiObject.capturePosthog(event: "start-focus-mode-manually", metadata: [:])
        appdelegate!.setIntentionInBrainDumpWindow()
        

        
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        self.view.window?.close()
    }
    
    @IBAction func btnStartFocusClicked(_ sender: Any) {
        addLog(text: "[user-action] startingFocusModeVc - btnStartFocusClicked")//
        let totalMinutes = (textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
        
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            if getHabitsVcObject().postponeTimer != nil {
                if getHabitsVcObject().postponeTimer!.isValid{
                    let currentTime = Date()
                    let breakTime = getHabitsVcObject().postponeTimer!.fireDate
                    let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                    if diffMinute < totalMinutes{
                        alertExtendPostpone = NSAlert()
                        alertExtendPostpone!.setSharingType()
                        alertExtendPostpone!.messageText = "Focus duration is longer than habit postpone duration."
                        alertExtendPostpone!.informativeText = "You may want to extend the postpone duration to match the focus session duration. Click on the desired button to start the focus session."
                        var buttonExtendPostponeText = "Extend postpone duration"
                        var buttonDoNotExtendPostponeText = "Do not extend postpone duration"
                        
                        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                            alertExtendPostpone!.messageText = pomodoroInfo.value(forKey: "alertExtendPostponeText") as? String ?? alertExtendPostpone!.messageText
                            alertExtendPostpone!.informativeText = pomodoroInfo.value(forKey: "alertExtendPostponeDescription") as? String ?? alertExtendPostpone!.informativeText
                            buttonExtendPostponeText = pomodoroInfo.value(forKey: "buttonExtendPostponeText") as? String ?? buttonExtendPostponeText
                            buttonDoNotExtendPostponeText = pomodoroInfo.value(forKey: "buttonDoNotExtendPostponeText") as? String ?? buttonDoNotExtendPostponeText
                        }
                        alertExtendPostpone!.alertStyle = NSAlert.Style.warning
                        alertExtendPostpone!.addButton(withTitle: buttonExtendPostponeText)
                        alertExtendPostpone!.addButton(withTitle: buttonDoNotExtendPostponeText)
                        
                        alertExtendPostpone!.beginSheetModal(for: self.view.window!, completionHandler: { [self] (modalResponse) in
                            if modalResponse == .alertFirstButtonReturn{
                                if currentState == ._POSTPON_MORNING_HABIT_{
                                    if SettingsManagerObject.isEasySkipEnabled{
                                        getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        self.checkTotalMinutesAndStart()
                                    }else{
                                        if SettingsManagerObject.isPasswordRequireInSkipMorning && shouldAskPassword(){
                                            self.presentAsSheet(self.enterPasswordVcObj!)
                                            self.enterPasswordVcObj?.parentVc = self
                                        }else{
                                            getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                            self.checkTotalMinutesAndStart()
                                        }
                                    }
                                }else if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
                                        var shouldAskPasswordForEvening = false
                                        if shouldAskPassword() &&  !SettingsManagerObject.isEasySkipEnabled{
                                            var isCutOffTimeGoing = false
                                            if cutOffTime != nil {
                                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                                                let currentDate = Date()
                                                if currentDate > cutOffDate{
                                                    isCutOffTimeGoing = true
                                                }
                                            }
                                            
                                            if isCutOffTimeGoing{
                                                if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                                    shouldAskPasswordForEvening = true
                                                }
                                            }else{
                                                if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                                    shouldAskPasswordForEvening = true
                                                }
                                            }
                                        }
                                        
                                        if shouldAskPasswordForEvening{
                                            self.presentAsSheet(self.enterPasswordVcObj!)
                                            self.enterPasswordVcObj?.parentVc = self
                                        }else{
                                            if currentState == ._EVENING_HABIT_{
                                                getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                            }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
                                                getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                                            }
                                            self.checkTotalMinutesAndStart()
                                        }
                                    
                                }
                            }else if modalResponse == .alertSecondButtonReturn{
                                self.checkTotalMinutesAndStart()
                            }
                        })
                        return;
                    }
                }
            }
        }
        
        checkTotalMinutesAndStart()
    }
    
    func checkTotalMinutesAndStart(){
        let totalMinutes = (textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
        
        if totalMinutes > 90{
            let alert: NSAlert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Tip: research indicates that 90 minutes is the maximum limit for focused work (ultradian rhythms). After that, your attention will naturally decline and you'll need to take a break."
            
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                    alert.messageText = startingFocusModeInfo.value(forKey: "tipMaximumMinutesText") as? String ?? alert.messageText
                }
            }
            
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: buttonOkText)
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                self.startFocusMode()
            })
        }else{
            startFocusMode()
        }
    }
    func startSameFocusBlockAgain(){
        getTaskPlayerVcObject().loadView()
        getTaskPlayerVcObject().loadRequest()
        
        startTimer()
        closePomodoroWindowIOfVisible()

        textFieldHourValue.integerValue = lastHourValue
        textFieldMinutesValue.integerValue = lastMinuteValue
        if lastSkipMicroBreakState{
            checkBoxSkipMicrobreaks.state = .on
        }else{
            checkBoxSkipMicrobreaks.state = .off
        }
        
        if isShowTimerInFocusEnabled{
            checkBoxShowTimer.state = .on
        }else{
            checkBoxShowTimer.state = .off
        }
        textViewQuestion.string = lastIntention
        //no need to save checkBoxSaveIntention state for this it willl remain same we are not changing it
        
        for i in 0..<arrFocusType.count{
            if let id = arrFocusType[i]["id"] as? String{
                if id == lastFocusModeId{
                    self.focusType = arrFocusType[i]["name"] as? String ?? ""
                    self.focusIndex = i
                    break;
                }
            }
        }
        
        
        
        
        btnStartFocus.isEnabled = true
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusType)//"Starting Focus type - \(focusType)"

        if arrFocusType[focusIndex]["isLockedFocus"] as? Bool == true{
            lblLockedFocusDescription.isHidden = false
            
            
            var appsArray = [String]()
            var appsUrlArray = [String]()
            if lastFrontMostApplication != nil{
                appsArray.append(lastFrontMostApplication!.bundleURL?.path ?? "")
                var appName = ""
                var appUrl = ""
                if let name = lastFrontMostApplication!.localizedName{
                    appName = name
                    let nameLowercased = name.lowercased()
                    
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        var defaultPageOfBrowser = ""
                        if browser == ._SAFARI_{
                            defaultPageOfBrowser = "favorites:"
                        }else if browser == ._MICROSOFT_EDGE_{
                            defaultPageOfBrowser = "edge://newtab"
                        }else if browser == ._SIGMA_OS_{
                            defaultPageOfBrowser = "sigma://newpage"
                        }else{
                            defaultPageOfBrowser = "chrome:"
                        }
                        
                        if let url = getActiveTabUrlOf(browser: browser){
                            if !url.contains(defaultPageOfBrowser){
                                let domain = getDomainFromUrl(url: url)
                                appsUrlArray = [domain]
                                appUrl = domain
                            }
                        }
                    }
                }
                
                if appsUrlArray.count == 0{
                    var onlyAllowSelectedAppText = "You'll only be able to use <APP>"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                            onlyAllowSelectedAppText = startingFocusModeInfo.value(forKey: "onlyAllowSelectedAppText") as? String ?? onlyAllowSelectedAppText
                        }
                    }
                    lblLockedFocusDescription.stringValue = onlyAllowSelectedAppText.replacingOccurrences(of: "<APP>", with: appName)//(in: "<APP>", with: appName)
                }else{
                    var onlyAllowSelectedAppAndUrlText = "You'll only be able to use \"<URL>\" in <APP>"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                            onlyAllowSelectedAppAndUrlText = startingFocusModeInfo.value(forKey: "onlyAllowSelectedAppAndUrlText") as? String ?? onlyAllowSelectedAppAndUrlText
                        }
                    }
                    onlyAllowSelectedAppAndUrlText = onlyAllowSelectedAppAndUrlText.replacingOccurrences(of: "<APP>", with: appName)
                    lblLockedFocusDescription.stringValue = onlyAllowSelectedAppAndUrlText.replacingOccurrences(of: "<URL>", with: appUrl)
                }
            }else{
                lblLockedFocusDescription.isHidden = true
            }
             
            var dic = arrFocusType[focusIndex]
            dic["allowed_urls"] = appsUrlArray
            dic["allowed_apps"] = appsArray
            dic["isAllowedAllApps"] = false
//            dic["isAllowedAllUrls"] = false#453
            dic["isAllowedListApproach"] = true
            arrFocusType[focusIndex] = dic

        }else{
            lblLockedFocusDescription.isHidden = true
        }
        
        
        lblTimeFocused.isHidden = true
        allActivityTodaySummaryData = nil
        var totalFocusCount = 0
        var totalFocusDuration = 0.0
        self.lblTimeFocused.stringValue = ""
        allApiObject.getAllActivityDaySummary(completionHandler: {dic in
            DispatchQueue.main.async {
                if allActivityTodaySummaryData != nil{
                    if let arr = allActivityTodaySummaryData!.value(forKey: "focusSummary") as? [[String:Any]]{
                        totalFocusCount = arr.count
                        for item in arr{
                            let duration = item["duration"] as? Double ?? 0
                            totalFocusDuration += duration
                        }
                    }
                }
                totalFocuseTime = totalFocusDuration
                self.lblTimeFocused.isHidden = false
                let duration = getStringTimeFromSeconds(seconds:Int(totalFocusDuration))
                var focusedText = "Total focused time: <DURATION> (<COUNT> focus sessions)"

                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                    if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                        focusedText = startingFocusModeInfo.value(forKey: "focusedText") as? String ?? focusedText
                    }
                }
                focusedText = focusedText.replacingOccurrences(of: "<DURATION>", with: "\(duration)")
                focusedText = focusedText.replacingOccurrences(of: "<COUNT>", with: "\(totalFocusCount)")
                self.lblTimeFocused.stringValue = focusedText
            }
        })
    }
    
    func ResetData(focusModeIndex:Int, focusType:String){
        getTaskPlayerVcObject().loadView()
        getTaskPlayerVcObject().loadRequest()
        
        if let index = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeStrictness) as? Int{
            sliderStrictness.integerValue = index
        }else{
            if SettingsManagerObject.isCuddlyModeEnabled{
                sliderStrictness.integerValue = 1
            }else{
                sliderStrictness.integerValue = 3
            }
        }
        textViewQuestion.string = ""
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroSkipMicroBreaks) as? Bool{
            if state{
                checkBoxSkipMicrobreaks.state = .on
            }else{
                checkBoxSkipMicrobreaks.state = .off
            }
        }else{
            checkBoxSkipMicrobreaks.state = .on
        }
        checkBoxShowTimer.state = .off
        checkBoxSaveIntention.state = .off
        startTimer()
        closePomodoroWindowIOfVisible()
        lastFocusModeId = arrFocusType[focusModeIndex]["id"] as? String ?? ""
        self.focusType = focusType
        self.focusIndex = focusModeIndex

        if let focusAlignmentScore = arrFocusType[focusIndex]["focusAlignmentScoreThreshold"] as? Int{
            popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(focusAlignmentScore)")
        }else{
            popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(defaultFocusAlignmentScoreToShowDistractingPopUp)")
        }

        if let lastHourValue = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeHourDuration) as? Int{
            textFieldHourValue.integerValue = lastHourValue
        }else{
            textFieldHourValue.stringValue = "00"
        }

        if let lastMinuteValue = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeMinuteDuration) as? Int{
            textFieldMinutesValue.integerValue = lastMinuteValue
        }else{
            textFieldMinutesValue.stringValue = "20"
        }
        
        btnStartFocus.isEnabled = true
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusType)//"Starting Focus type - \(focusType)"
        
        if let val = UserDefaults.standard.value(forKey: kUserdefaultsLastFocusSavedIntention) as? String{
            textViewQuestion.string = val
        }

        let lastIntentionUsed = arrFocusType[focusIndex]["lastIntentionUsed"] as? String ?? ""
        
        btnInfo.isHidden = false
        lblExplanation.isHidden = true
        textViewQuestion.string = lastIntentionUsed
        
        if let isDefault = arrFocusType[focusIndex]["isDefault"] as? Bool{
            if  isDefault{
                
                var warningDefaultFocusMode = "Heads up: this will not use AI blocking. Focus Bear will only block the sites in your super distracting sites list"
                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                    if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                        warningDefaultFocusMode = startingFocusModeInfo.value(forKey: "warningDefaultFocusMode") as? String ?? warningDefaultFocusMode
                    }
                }
                
                showTooltip(sender: lblTitle, msg: warningDefaultFocusMode, preferredEdge: .minX, maxWidthVal: 250) 
            }
        }
        
        
        if arrFocusType[focusIndex]["isLockedFocus"] as? Bool == true{
            lblLockedFocusDescription.isHidden = false
            
            
            var appsArray = [String]()
            var appsUrlArray = [String]()
            if lastFrontMostApplication != nil{
                appsArray.append(lastFrontMostApplication!.bundleURL?.path ?? "")
                var appName = ""
                var appUrl = ""
                if let name = lastFrontMostApplication!.localizedName{
                    appName = name
                    let nameLowercased = name.lowercased()
                    
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        var defaultPageOfBrowser = ""
                        if browser == ._SAFARI_{
                            defaultPageOfBrowser = "favorites:"
                        }else if browser == ._MICROSOFT_EDGE_{
                            defaultPageOfBrowser = "edge://newtab"
                        }else if browser == ._SIGMA_OS_{
                            defaultPageOfBrowser = "sigma://newpage"
                        }else{
                            defaultPageOfBrowser = "chrome:"
                        }
                        
                        if let url = getActiveTabUrlOf(browser: browser){
                            if !url.contains(defaultPageOfBrowser){
                                let domain = getDomainFromUrl(url: url)
                                appsUrlArray = [domain]
                                appUrl = domain
                            }
                        }
                    }
                }
                
                if appsUrlArray.count == 0{
                    var onlyAllowSelectedAppText = "You'll only be able to use <APP>"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                            onlyAllowSelectedAppText = startingFocusModeInfo.value(forKey: "onlyAllowSelectedAppText") as? String ?? onlyAllowSelectedAppText
                        }
                    }
                    lblLockedFocusDescription.stringValue = onlyAllowSelectedAppText.replacingOccurrences(of: "<APP>", with: appName)//(in: "<APP>", with: appName)
                }else{
                    var onlyAllowSelectedAppAndUrlText = "You'll only be able to use \"<URL>\" in <APP>"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                            onlyAllowSelectedAppAndUrlText = startingFocusModeInfo.value(forKey: "onlyAllowSelectedAppAndUrlText") as? String ?? onlyAllowSelectedAppAndUrlText
                        }
                    }
                    onlyAllowSelectedAppAndUrlText = onlyAllowSelectedAppAndUrlText.replacingOccurrences(of: "<APP>", with: appName)
                    lblLockedFocusDescription.stringValue = onlyAllowSelectedAppAndUrlText.replacingOccurrences(of: "<URL>", with: appUrl)
                }
            }else{
                lblLockedFocusDescription.isHidden = true
            }
             
            var dic = arrFocusType[focusIndex]
            dic["allowed_urls"] = appsUrlArray
            dic["allowed_apps"] = appsArray
            dic["isAllowedAllApps"] = false
//            dic["isAllowedAllUrls"] = false#453
            dic["isAllowedListApproach"] = true
            arrFocusType[focusIndex] = dic

        }else{
            lblLockedFocusDescription.isHidden = true
        }
        lblTimeFocused.isHidden = true
        allActivityTodaySummaryData = nil
        var totalFocusCount = 0
        var totalFocusDuration = 0.0
        self.lblTimeFocused.stringValue = ""
        allApiObject.getAllActivityDaySummary(completionHandler: {dic in
            DispatchQueue.main.async {
                if allActivityTodaySummaryData != nil{
                    if let arr = allActivityTodaySummaryData!.value(forKey: "focusSummary") as? [[String:Any]]{
                        totalFocusCount = arr.count
                        for item in arr{
                            let duration = item["duration"] as? Double ?? 0
                            totalFocusDuration += duration
                        }
                    }
                }
                totalFocuseTime = totalFocusDuration
                self.lblTimeFocused.isHidden = false
                let duration = getStringTimeFromSeconds(seconds:Int(totalFocusDuration))
                var focusedText = "Total focused time: <DURATION> (<COUNT> focus sessions)"

                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                    if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                        focusedText = startingFocusModeInfo.value(forKey: "focusedText") as? String ?? focusedText
                    }
                }
                focusedText = focusedText.replacingOccurrences(of: "<DURATION>", with: "\(duration)")
                focusedText = focusedText.replacingOccurrences(of: "<COUNT>", with: "\(totalFocusCount)")
                self.lblTimeFocused.stringValue = focusedText
            }
        })
        
        
    }
    @IBAction func checkBoxSkipMicrobreaksClicked(_ sender: Any) {
        if checkBoxSkipMicrobreaks.state == .on{
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsPomodoroSkipMicroBreaks)
        }else{
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsPomodoroSkipMicroBreaks)
        }
    }

    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldHourValue{
                var count = textfield.integerValue
                if count > 12{
                    count = 12
                }
                if count < 10{
                    textfield.stringValue = "0\(count)"
                }else{
                    textfield.stringValue = "\(count)"
                }
                
                if textfield.stringValue.count > 2{
                    textfield.stringValue = "12"
                }
                
                if textFieldMinutesValue.stringValue == "00" && textFieldHourValue.stringValue == "00"{
                    btnStartFocus.isEnabled = false
                }else{
                    btnStartFocus.isEnabled = true
                }
            }else if textfield == textFieldMinutesValue{
                let count = textfield.integerValue
                if count < 10{
                    textfield.stringValue = "0\(count)"
                }else{
                    textfield.stringValue = "\(count)"
                }
                if textFieldMinutesValue.stringValue == "00" && textFieldHourValue.stringValue == "00"{
                    btnStartFocus.isEnabled = false
                }else{
                    btnStartFocus.isEnabled = true
                }
            }
        }
    }

//    @IBAction func btnFrictionLevelInfoClicked(_ sender: Any) {
//        var msg = "You can stop focusing at any time"
//        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                msg = startingFocusModeInfo.value(forKey: "tooltipFrictionLevelLowText") as? String ?? msg
//            }
//        }
//
//        showTooltip(sender: btnFrictionLevelInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//    }
        
    @IBAction func btnStrictnessNormalClicked(_ sender: Any) {
        var msg = "can pause/stop focus session at any time"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                msg = startingFocusModeInfo.value(forKey: "strictnessNormalTooltip") as? String ?? msg
            }
        }
        
        showTooltip(sender: btnStrictnessNormal, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnStrictnessStrictClicked(_ sender: Any) {
        var msg = "requires countdown timer before pausing/stopping focus session"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                msg = startingFocusModeInfo.value(forKey: "strictnessStrictTooltip") as? String ?? msg
            }
        }
        
        showTooltip(sender: btnStrictnessStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }

    @IBAction func btnStrictnessSuperStrictClicked(_ sender: Any) {
        var msg = "immediately block urls + prevents pausing/stopping focus session or opening settings"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                msg = startingFocusModeInfo.value(forKey: "strictnessSuperStrictTooltip") as? String ?? msg
            }
        }
        
        showTooltip(sender: btnStrictnessSuperStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    @IBAction func sliderStrictnessClicked(_ sender: Any) {
        if sliderStrictness.integerValue == 3{
            var strictnessSuperStrictClickedText = "I understand I cannot stop this focus session until it ends. I am committed to avoiding distractions and getting a ton of work done."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                    strictnessSuperStrictClickedText = startingFocusModeInfo.value(forKey: "strictnessSuperStrictClickedText") as? String ?? strictnessSuperStrictClickedText
                }
            }
            showTooltip(sender: sliderStrictness, msg: strictnessSuperStrictClickedText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
    }
}




