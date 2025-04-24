//
//  firstViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {
    
    @IBOutlet weak var boxNewBadge: customNewBadgeBox!
    @IBOutlet weak var btnSelectHabitsToDo: underLineButton!
    @IBOutlet weak var lblSelectHabits: NSTextField!
    @IBOutlet weak var boxScrollView: NSBox!
    @IBOutlet weak var btnEditHabits: Button!
    @IBOutlet weak var lblTitleSelectActivity: NSTextField!
    @IBOutlet weak var lblTitleEnterActivityName: NSTextField!
    @IBOutlet weak var textFieldActivity: NSTextField!
    @IBOutlet weak var popUpBtnActivities: NSPopUpButton!
    @IBOutlet weak var boxSelectActivities: NSBox!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var btnPostponeBreak: underLineButton!
    @IBOutlet weak var btnTopSpace: NSLayoutConstraint!
    @IBOutlet weak var btnBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var imgViewBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var imgViewTopSpace: NSLayoutConstraint!
    @IBOutlet weak var imgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lbltimer: NSTextField!
    @IBOutlet weak var scrollViewHabits: NSScrollView!

    @IBOutlet weak var imgView: NSImageView!
    //    @IBOutlet weak var btnWidth: NSLayoutConstraint!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStartFirstHabit: NSButton!
    @IBOutlet weak var tblViewHabits: NSTableView!
    @IBOutlet weak var btnInfo: cursorButton!
    
    var isFirstTime = false
    var introActivities = [NSDictionary]()
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0
    var chooseHabitsVCObj: chooseHabitsVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnStartFirstHabit.cell?.wraps = true
        btnSelectHabitsToDo.title = "I don't have time for all these habits"
        lblSelectHabits.stringValue = "Select the habit you want to do first and click \"Begin Habits\""
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            lblSelectHabits.stringValue = activityInfo.value(forKey: "selectHabitText") as? String ?? lblSelectHabits.stringValue
            btnSelectHabitsToDo.title = activityInfo.value(forKey: "buttonSelectHabitsText") as? String ?? btnSelectHabitsToDo.title
        }
        
        btnEditHabits.title = "Customise my habits first"
        lblTitleSelectActivity.stringValue = "What 30 seconds of activity do you want to do?"
        lblTitleEnterActivityName.stringValue = "Enter name of activity"
        
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            lblTitleSelectActivity.stringValue = dic.value(forKey: "titleSelectActivity") as? String ?? lblTitleSelectActivity.stringValue
            lblTitleEnterActivityName.stringValue = dic.value(forKey: "titleEnterActivityName") as? String ?? lblTitleEnterActivityName.stringValue
            btnEditHabits.title = dic.value(forKey: "buttonEditHabitsText") as? String ?? btnEditHabits.title
        }
        textFieldActivity.delegate = self
        
        btnEditHabits.buttonColor = NSColor.white.cgColor
        lblSelectHabits.isHidden = true
        boxNewBadge.isHidden = true
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        btnInfo.isHidden = true
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            if isHabitsDisabled{
                lblSubTitle.stringValue = "Throughout the day, I'll remind you to take regular breaks to keep your mind sharp and your body flexible. Here's an example of a break activity: 30 seconds of deep breathing."
                if let subTitle = dic.value(forKey: "welcomeMessageOnlyBreakIntro") as? String{
                    lblSubTitle.stringValue = subTitle
                }
            }else{
                if let subTitle = dic.value(forKey: "welcomeMessageIntro") as? String{
                    lblSubTitle.stringValue = subTitle
                }
            }
        }
    }
    
    override func viewWillAppear() {
        boxSelectActivities.isHidden = true
        lbltimer.isHidden = true
        btnStartFirstHabit.isEnabled = true
        btnInfo.isHidden = true
        btnEditHabits.isHidden = true
        if isFirstTime{
            btnSelectHabitsToDo.isHidden = true
            lblSelectHabits.isHidden = true
            textFieldActivity.isHidden = true
            lblTitleEnterActivityName.isHidden = true
            allApiObject.capturePosthog(event: "start-onboarding-activity-shown", metadata: [:])
            btnPostponeBreak.isHidden = false
            btnPostponeBreak.title = "Skip"
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                btnPostponeBreak.title = dic.value(forKey: "buttonSkipText") as? String ?? btnPostponeBreak.title
            }
            lblProgress.isHidden = true
            imgView.image = NSImage(named: "icon 130")//
            imgViewHeight.constant = 160
            imgViewTopSpace.constant = 35
            imgViewBottomSpace.constant = 5
            lblSubTitle.isHidden = false
            tblViewHabits.isHidden = true
            scrollViewHabits.isHidden = true
            btnBottomSpace.constant = 63
            btnTopSpace.constant = 171
            let welcomeText = "Let’s take a quick 30 second break"
            btnInfo.isHidden = false
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "welcomeMessageHeading") as? String ?? welcomeText
                
                lblSubTitle.stringValue = "Taking breaks throughout the day helps with stress and focus."
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    if let subTitle = dic.value(forKey: "takingBreaksText") as? String{
                        lblSubTitle.stringValue = subTitle
                    }
                }
                
                if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                    introActivities = arr
                    let name = arr.first?.value(forKey: "name") as? String ?? ""
                    let durationSeconds = arr.first?.value(forKey: "duration_seconds") as? Int ?? 0
                    let videoUrl = arr.first?.value(forKey: "video_urls") as? [String] ?? []
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                    introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[], tutorial: "")
                    btnStartFirstHabit.isEnabled = true
                    
                    
                    popUpBtnActivities.removeAllItems()
                    for item in arr{
                        popUpBtnActivities.addItem(withTitle: item.value(forKey: "name") as? String ?? "")
                    }
                    popUpBtnActivities.selectItem(at: 0)
                    boxSelectActivities.isHidden = false
                }else{
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                    btnStartFirstHabit.toolTip = btnStartFirstHabit.title
                    introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[], tutorial: "")
                }
            }else{
                introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[], tutorial: "")
                lblTitle.stringValue = welcomeText
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                btnStartFirstHabit.toolTip = btnStartFirstHabit.title
            }
        }else{
            if currentState == ._MORNING_HABIT_{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
                if arrPreFilteredMorningHabits.count == 1{
                    btnSelectHabitsToDo.isHidden = true
                }else{
                    btnSelectHabitsToDo.isHidden = false
                }
                UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                btnEditHabits.isHidden = false
                if editHabitRoutineVcObj == nil{
                    getEditHabitRoutineVcObject().loadView()
                }
                lblSelectHabits.isHidden = false
                btnPostponeBreak.isHidden = true
                lblProgress.isHidden = true
                btnBottomSpace.constant = 100
                btnTopSpace.constant = 60
                if SettingsManagerObject.kIsReducedMotion{
                    imgView.image = nil
                    imgViewHeight.constant = 40
                    imgViewTopSpace.constant = 35
                    imgViewBottomSpace.constant = 5
                }else{
                    imgViewHeight.constant = 160
                    imgViewTopSpace.constant = 15
                    imgViewBottomSpace.constant = 0
                    imgView.image = NSImage(named: "Waking up _ SMall")
                    imgView.animates = true
                }
                habitTotalCompletedSeconds = 0
                lblTitle.stringValue = startMorningHabitTitleText
                btnStartFirstHabit.title = "Begin"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnStartFirstHabit.title = activityInfo.value(forKey: "buttonBeginText") as? String ?? btnStartFirstHabit.title
                }
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                if !getvisualizeInstructionsObject().isViewLoaded{
                    getvisualizeInstructionsObject().loadView()
                }
                getvisualizeInstructionsObject().tryPreLoadMotivationalMessage()
                
            }else if currentState == ._EVENING_HABIT_{
                if arrPreFilteredEveningHabits.count == 1{
                    btnSelectHabitsToDo.isHidden = true
                }else{
                    btnSelectHabitsToDo.isHidden = false
                }
                btnEditHabits.isHidden = false
                if editHabitRoutineVcObj == nil{
                    getEditHabitRoutineVcObject().loadView()
                }
                btnPostponeBreak.isHidden = true
                lblSelectHabits.isHidden = false
                lblProgress.isHidden = true
                btnTopSpace.constant = 60
                btnBottomSpace.constant = 100
                imgView.image = nil
                imgViewHeight.constant = 40
                imgViewTopSpace.constant = 35
                imgViewBottomSpace.constant = 5
                lblTitle.stringValue = startEveningHabitTitleText
                habitTotalCompletedSeconds = 0
                
                btnStartFirstHabit.title = "Begin"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnStartFirstHabit.title = activityInfo.value(forKey: "buttonBeginText") as? String ?? btnStartFirstHabit.title
                }
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                if !getvisualizeInstructionsObject().isViewLoaded{
                    getvisualizeInstructionsObject().loadView()
                }
                getvisualizeInstructionsObject().tryPreLoadMotivationalMessage()
            }else if currentState == ._ACTIVITY_{
                btnSelectHabitsToDo.isHidden = true
                btnEditHabits.isHidden = true
                btnPostponeBreak.isHidden = false
                lblProgress.isHidden = false
                lblSelectHabits.isHidden = true
                
                btnPostponeBreak.title = "Skip this habit for today"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnPostponeBreak.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnPostponeBreak.title
                }
                
                lblTitle.stringValue = thirdVcObj?.lblTitle.stringValue ?? ""
                btnStartFirstHabit.title = thirdVcObj?.btnMain.title ?? ""
                
                lblProgress.stringValue = thirdVcObj?.lblProgress.stringValue ?? ""
                                
                btnTopSpace.constant = 134
                btnBottomSpace.constant = 100
                imgView.image = nil
                imgViewHeight.constant = 40
                imgViewTopSpace.constant = 35
                imgViewBottomSpace.constant = 5
                habitTotalCompletedSeconds = 0

                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                lblSubTitle.isHidden = true
            }else if currentState == ._CUSTOM_ROUTINE_{
                if arrAllCustomRoutine[currentRoutineIndex].arrAllHabits.count == 1{
                    btnSelectHabitsToDo.isHidden = true
                }else{
                    btnSelectHabitsToDo.isHidden = false
                }
                btnEditHabits.isHidden = true
                lblSelectHabits.isHidden = false
                btnPostponeBreak.isHidden = true
                lblProgress.isHidden = true
                btnBottomSpace.constant = 100
                btnTopSpace.constant = 60
                if SettingsManagerObject.kIsReducedMotion{
                    imgView.image = nil
                    imgViewHeight.constant = 40
                    imgViewTopSpace.constant = 35
                    imgViewBottomSpace.constant = 5
                }else{
                    imgViewHeight.constant = 160
                    imgViewTopSpace.constant = 15
                    imgViewBottomSpace.constant = 0
                    imgView.image = NSImage(named: "Waking up _ SMall")
                    imgView.animates = true
                }
                lblTitle.stringValue = "Your personalized routine is waiting! Take one step at a time and make the most of your day."
                btnStartFirstHabit.title = "Begin"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnStartFirstHabit.title = activityInfo.value(forKey: "buttonBeginText") as? String ?? btnStartFirstHabit.title
                    lblTitle.stringValue = activityInfo.value(forKey: "startCustomRoutineTitleText") as? String ?? lblTitle.stringValue
                }
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                if !getvisualizeInstructionsObject().isViewLoaded{
                    getvisualizeInstructionsObject().loadView()
                }
                getvisualizeInstructionsObject().tryPreLoadMotivationalMessage()
                
            }
        }
    }
    
    
    override func viewDidAppear() {
        if currentState == ._CUSTOM_ROUTINE_{
            return;
        }
        if isFirstTime{
            showOnboardingProgress(view: self.view, progress: 12)
            showOnboardingBellIcon(view: self.view, screen: "start-onboarding-activity-screen")
        }
        var isAnyNagVisible = false
        if currentState == ._MORNING_HABIT_{
            var shouldShowImpactMeasurementView = true
            if lateMorningHabitPopupVcObj != nil{
                if lateMorningHabitPopupVcObj?.presentingViewController == self{
                    shouldShowImpactMeasurementView = false
                    isAnyNagVisible = true
                }
            }
            if shouldShowImpactMeasurementView{
                let currentDate = Date()
                let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
                let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
                if diffDays > 2{
                    if UserDefaults.standard.object(forKey: kUserdefaultsImpactMeasurementShown) == nil{
                        UserDefaults.standard.set(true, forKey: kUserdefaultsImpactMeasurementShown)
                        allApiObject.capturePosthog(event: "show-recordimpact-permission", metadata: [:])
                        self.presentAsSheet(getImpactMeasurementVcObject())
                        isAnyNagVisible = true
                    }
                }
            }
            if !isAnyNagVisible{
                showLimitedUsgaeViewIfNeeded()
            }
        }else{
            showLimitedUsgaeViewIfNeeded()
        }

        if !isAnyNagVisible{
            if alertLimitedUsageVcObj != nil{
                if alertLimitedUsageVcObj?.presentingViewController == self{
                    isAnyNagVisible = true
                }
            }
        }
        if !isAnyNagVisible{
            showConfirmRoutineDurationViewIfNeeded()
        }
        
    }
 
    func showLimitedUsgaeViewIfNeeded(){// after 7 trial days
        if isExpired && isActivitiesReducedInExpiredApp{
            if alertLimitedUsageVcObj != nil{
                if alertLimitedUsageVcObj?.presentingViewController != self{
                    allApiObject.capturePosthog(event: "alert-limited-usage-shown", metadata: [:])
                    self.presentAsSheet(getAlertLimitedUsageVcObject())
                }
            }else{
                allApiObject.capturePosthog(event: "alert-limited-usage-shown", metadata: [:])
                self.presentAsSheet(getAlertLimitedUsageVcObject())
            }
        }
    }
    
    //Handle user opening habits well after routine start time #920
    func checkMorningHabitDelayTime(){
        if impactMeasurementVcObj != nil{
            if impactMeasurementVcObj?.presentingViewController == self{
                impactMeasurementVcObj?.dismiss(impactMeasurementVcObj)
            }
        }
        if currentState == ._MORNING_HABIT_{
            if lateMorningHabitPopupVcObj != nil{
                if lateMorningHabitPopupVcObj?.presentingViewController == self{
                    return;
                }
            }
            
            var shouldShowAlert = false
            if let beginMorningHabitClickedDate = UserDefaults.standard.object(forKey: kUserdefaultsBeginMorningHabitClickedDate) as? Date{
                if Calendar.current.isDateInToday(beginMorningHabitClickedDate){
                    shouldShowAlert = false
                }else{
                    shouldShowAlert = true
                }
            }else{
                shouldShowAlert = true
            }
            if shouldShowAlert{
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let currentDate = Date()
                let diffHours = Calendar.current.dateComponents([.hour], from: startDate, to: currentDate).hour ?? 0
                if diffHours > 3{
                    self.presentAsSheet(getLateMorningHabitPopupVcObject())
                }
            }
        }
    }
    
    func showConfirmRoutineDurationViewIfNeeded(){
        if confirmRoutineDurationVcObj != nil{
            if confirmRoutineDurationVcObj?.presentingViewController == self{
                return;
            }
        }
        
        var shouldShowAlert = false
        var dateUserdefaults = ""
        if currentState == ._MORNING_HABIT_{
            dateUserdefaults = kUserdefaultsBeginMorningHabitClickedDate
        }else if currentState == ._EVENING_HABIT_{
            dateUserdefaults = kUserdefaultsBeginEveningHabitClickedDate
        }else{
            return;
        }
        if let beginHabitClickedDate = UserDefaults.standard.object(forKey: dateUserdefaults) as? Date{
            if Calendar.current.isDateInToday(beginHabitClickedDate){
                shouldShowAlert = false
            }else{
                shouldShowAlert = true
            }
        }else{
            shouldShowAlert = true
        }
        
        
        if shouldShowAlert{
            var totalSecondsAllHabits = 0
            if currentState == ._MORNING_HABIT_{
                for i in 0..<arrFilteredMorningHabits.count{
                    if arrFilteredMorningHabits[i].useTimer{
                        totalSecondsAllHabits += arrFilteredMorningHabits[i].durationSeconds
                    }else{
                        if let arrDuartions = nonTimerBasedHabitsObject.arrNonTimerBasedHabitsDurations[arrFilteredMorningHabits[i].id]{
                            let sum = arrDuartions.reduce(0, +)
                            let averageValue =  sum / arrDuartions.count
                            totalSecondsAllHabits += averageValue
                        }
                    }
                }
            }else if currentState == ._EVENING_HABIT_{
                for i in 0..<arrFilteredEveningHabits.count{
                        if isHighPrioritySequenceGoing{
                            if arrFilteredEveningHabits[i].isPriorityHigh{
                                if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                    let currentDate = Date()
                                    if currentDate > cutOffDate{
                                        addLog(text: " func showConfirmRoutineDurationViewIfNeeded")// remove this
                                        addLog(text: "evening habit skipped:- this next habit is high priority habit but cutoff time of this habit has passed:- \(arrFilteredEveningHabits[i].name)  \(arrFilteredEveningHabits[i].id)") // remove this
                                        continue;
                                    }
                                }
                                if arrFilteredEveningHabits[i].useTimer{
                                    totalSecondsAllHabits += arrFilteredEveningHabits[i].durationSeconds
                                }else{
                                    if let arrDuartions = nonTimerBasedHabitsObject.arrNonTimerBasedHabitsDurations[arrFilteredEveningHabits[i].id]{
                                        let sum = arrDuartions.reduce(0, +)
                                        let averageValue =  sum / arrDuartions.count
                                        totalSecondsAllHabits += averageValue
                                    }
                                }
                            }
                        }else{
                            if arrFilteredEveningHabits[i].useTimer{
                                totalSecondsAllHabits += arrFilteredEveningHabits[i].durationSeconds
                            }else{
                                if let arrDuartions = nonTimerBasedHabitsObject.arrNonTimerBasedHabitsDurations[arrFilteredEveningHabits[i].id]{
                                    let sum = arrDuartions.reduce(0, +)
                                    let averageValue =  sum / arrDuartions.count
                                    totalSecondsAllHabits += averageValue
                                }
                            }
                        }
                }
            }
            if totalSecondsAllHabits != 0{
                addLog(text: "confirm Routine Duration view shown")
                allApiObject.capturePosthog(event: "confirm-routine-duration-shown", metadata: [:])
                self.presentAsSheet(getConfirmRoutineDurationVcObject())
                getConfirmRoutineDurationVcObject().resetData(totalSeconds: totalSecondsAllHabits)
            }
        }
    }

    @IBAction func popUpBtnActivitiesClicked(_ sender: Any) {
        let index = popUpBtnActivities.indexOfSelectedItem
        let name = introActivities[index].value(forKey: "name") as? String ?? ""
        let durationSeconds = introActivities[index].value(forKey: "duration_seconds") as? Int ?? 0
        let videoUrl = introActivities[index].value(forKey: "video_urls") as? [String] ?? []
        btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
        introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[], tutorial: "")
        
        btnStartFirstHabit.isEnabled = true
        lblTitleEnterActivityName.isHidden = true
        textFieldActivity.isHidden = true
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "[user-action] firstViewController:- button Postpone Clicked")
        if currentState == ._BREATHING_{
            mainViewControllerObj?.abortCurrentState()
            return;
        }
        thirdVcObj?.btnSkipHabitClicked(self)//for breakActivity only
    }
    
    
    @IBAction func btnEditHabitsClicked(_ sender: Any) {
        if shouldAskPassword(){
            if SettingsManagerObject.isPasswordRequireInChangeSettings{
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                showEditHabitsView()
            }
        }else{
            showEditHabitsView()
        }
    }
    func showEditHabitsView(){
        allApiObject.capturePosthog(event: "customise-habits-first-shown", metadata: [:])
        btnEditHabits.isHidden = true
        self.view.addSubview(getEditHabitRoutineVcObject().view)
        self.view.addConstraints(subView: getEditHabitRoutineVcObject().view)
    }
    override func viewWillDisappear() {
        if lateMorningHabitPopupVcObj != nil{
            if lateMorningHabitPopupVcObj?.presentingViewController == self{
                lateMorningHabitPopupVcObj?.dismiss(lateMorningHabitPopupVcObj)
            }
        }
        if alertLimitedUsageVcObj != nil{
            if alertLimitedUsageVcObj?.presentingViewController == self{
                alertLimitedUsageVcObj?.dismiss(alertLimitedUsageVcObj)
            }
        }
        if editHabitRoutineVcObj != nil{
            if self.view.subviews.contains(getEditHabitRoutineVcObject().view){
                getEditHabitRoutineVcObject().view.removeFromSuperview()
            }
        }
        if confirmRoutineDurationVcObj != nil{
            if confirmRoutineDurationVcObj?.presentingViewController == self{
                confirmRoutineDurationVcObj?.dismiss(confirmRoutineDurationVcObj)
            }
        }
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    
    @IBAction func btnStartFirstHabitClicked(_ sender: Any) {
        addLog(text: "[user-action] btnStartFirstHabitClicked")
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
            if enterPasswordVcObj != nil{
                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                    return;
                }
            }
        }
        if isFirstTime{
            mainViewControllerObj?.startBreathing()
        }else{
            if currentState == ._MORNING_HABIT_{
                if tblViewHabits.selectedRow != 0 && tblViewHabits.selectedRow != -1{
                    var tempArr = arrFilteredMorningHabits
                    arrFilteredMorningHabits.removeAll()
                    arrFilteredMorningHabits.append(tempArr[tblViewHabits.selectedRow])
                    tempArr.remove(at: tblViewHabits.selectedRow)
                    for item in tempArr{
                        arrFilteredMorningHabits.append(item)
                    }
                }
                mainViewControllerObj?.showVisualizeInstructionsVc()
                visualizeInstructionsVcObj?.startTimer()
                allApiObject.capturePosthog(event: "visualize-morning-routine", metadata: ["routine-type":"morning_routine"])
                UserDefaults.standard.set(Date(), forKey: kUserdefaultsBeginMorningHabitClickedDate)
            }else if currentState == ._EVENING_HABIT_{
                if tblViewHabits.selectedRow != 0 && tblViewHabits.selectedRow != -1{
                    var tempArr = arrFilteredEveningHabits
                    arrFilteredEveningHabits.removeAll()
                    arrFilteredEveningHabits.append(tempArr[tblViewHabits.selectedRow])
                    tempArr.remove(at: tblViewHabits.selectedRow)
                    for item in tempArr{
                        arrFilteredEveningHabits.append(item)
                    }
                }
                
                if isHighPrioritySequenceGoing{
                    for i in 0..<arrFilteredEveningHabits.count{
                        if arrFilteredEveningHabits[i].isPriorityHigh{
                            
                            if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                let currentDate = Date()
                                if currentDate > cutOffDate{
                                    addLog(text: " func btnStartFirstHabitClicked")// remove this
                                    addLog(text: "evening habit skipped:- this first habit is high priority habit but cutoff time of this habit has passed:- \(arrFilteredEveningHabits[i].name)  \(arrFilteredEveningHabits[i].id)") // remove this
                                    continue;
                                }
                            }
                            
                            currentHabitIndex = i - 1
                            break;
                        }
                    }
                }else{
                    currentHabitIndex = -1
                }
                
                
                mainViewControllerObj?.showVisualizeInstructionsVc()
                visualizeInstructionsVcObj?.startTimer()
                allApiObject.capturePosthog(event: "visualize-evening-routine", metadata: ["routine-type":"evening_routine"])
                UserDefaults.standard.set(Date(), forKey: kUserdefaultsBeginEveningHabitClickedDate)
            }else if currentState == ._ACTIVITY_{
                thirdVcObj?.btnMainClicked(self)
            }else if currentState == ._CUSTOM_ROUTINE_{
                if tblViewHabits.selectedRow != 0 && tblViewHabits.selectedRow != -1{
                    var tempArr = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.removeAll()
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.append(tempArr[tblViewHabits.selectedRow])
                    tempArr.remove(at: tblViewHabits.selectedRow)
                    for item in tempArr{
                        arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.append(item)
                    }
                }
                mainViewControllerObj?.showVisualizeInstructionsVc()
                visualizeInstructionsVcObj?.startTimer()
                allApiObject.capturePosthog(event: "visualize-morning-routine", metadata: ["routine-type":"custom_routine"])
            }
        }
    }

    @IBAction func btnSelectHabitsToDoClicked(_ sender: Any) {
        showChooseHabitsView()
    }
    
    func showChooseHabitsView(){
        addLog(text: "showChooseHabitsView")
        if chooseHabitsVCObj == nil{
            chooseHabitsVCObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("chooseHabitsVC")) as? chooseHabitsVC
        }
        chooseHabitsVCObj!.currentHabitIndex = currentHabitIndex
        self.presentAsSheet(chooseHabitsVCObj!)
    }
    
}
extension firstViewController:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if currentState == ._MORNING_HABIT_{
            return  arrFilteredMorningHabits.count
        }else if currentState == ._EVENING_HABIT_{
            return  arrFilteredEveningHabits.count
        }else if currentState == ._ACTIVITY_{
            return  arrFinalBreakActivities.count
        }else if currentState == ._CUSTOM_ROUTINE_{
            return  arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count
        }else{
            return 0
        }
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            cell.boxBg.fillColor = NSColor.clear
            cell.lblTitle.textColor = NSColor.labelColor
            if currentState == ._MORNING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredMorningHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.systemBlue
                    cell.lblTitle.textColor = NSColor.white
                }
            }else if currentState == ._EVENING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredEveningHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.systemBlue
                    cell.lblTitle.textColor = NSColor.white
                }
            }else if currentState == ._ACTIVITY_{
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = -1
                var activityName = ""
                let duration = arrFinalBreakActivities[row].activity.durationSeconds ?? 0
                if let choice = arrFinalBreakActivities[row].randomChoice{
                    activityName = choice.name
                }else{
                    activityName = arrFinalBreakActivities[row].activity.name ?? ""
                }
                if arrFinalBreakActivities[row].activity.useTimer{
                    cell.lblTitle.stringValue  = "\(row + 1).   \(activityName) - \(getStringTime(seconds: duration))"
                }else{
                    cell.lblTitle.stringValue  = "\(row + 1).   \(activityName)"
                }
                
            }else if currentState == ._CUSTOM_ROUTINE_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.systemBlue
                    cell.lblTitle.textColor = NSColor.white
                }
            }
            
            return cell
        }
        
        return NSTableCellView()
    }
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if row != 0 && !SettingsManagerObject.isOutOfOrderHabitsAllowed{
            return false
        }
        return true
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblViewHabits.selectedRow == -1{
            return;
        }
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
            for row in 0..<tblViewHabits.numberOfRows{
                if let cell = tblViewHabits.view(atColumn: 0, row: row, makeIfNecessary: true) as? tblCellHabits{
                    cell.boxBg.fillColor = NSColor.clear
                    cell.lblTitle.textColor = NSColor.labelColor
                }
            }
            
            if let cell = tblViewHabits.view(atColumn: 0, row: tblViewHabits.selectedRow, makeIfNecessary: true) as? tblCellHabits{
                cell.boxBg.fillColor = NSColor.systemBlue
                cell.lblTitle.textColor = NSColor.white
            }
        }
    }
}

extension firstViewController:NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField{
            if textField == self.textFieldActivity{
                let title = textField.stringValue
                let index = popUpBtnActivities.indexOfSelectedItem
                var name = introActivities[index].value(forKey: "name") as? String ?? ""
                let durationSeconds = introActivities[index].value(forKey: "duration_seconds") as? Int ?? 0
                let videoUrl = introActivities[index].value(forKey: "video_urls") as? [String] ?? []
                if title.isEmpty{
                    btnStartFirstHabit.isEnabled = false
                }else{
                    name = title
                    btnStartFirstHabit.isEnabled = true
                }
                
                
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[], tutorial: "")
                
            }
        }
    }
}
