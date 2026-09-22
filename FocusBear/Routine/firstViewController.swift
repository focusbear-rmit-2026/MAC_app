//
//  firstViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {
    
    
    @IBOutlet weak var heightBoxScrollView: NSLayoutConstraint!
    @IBOutlet weak var boxSegmentControlOfficeMode: NSBox!
    @IBOutlet weak var segmentControlOfficeMode: NSSegmentedControl!
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
    var segmentOfficeModeTrackingArea: NSTrackingArea?
    var segmentWfhModeTrackingArea: NSTrackingArea?
    var toolTipOfficeMode = "When you're working from the office, I will only give you appropriate break activities (e.g. chair stretches rather than pushups)."
    var toolTipWfhMode = "No-one's around! You can do break activities that are a bit more fun, e.g. Dance like no-one's watching"
    var btnTopSpaceValue:CGFloat = 60
    var passwordWindowShowingForMarkHabitComplete = false
    var passwordWindowShowingForMarkHabitSkip = false
    // #2012: a past morning habit (Day Plan "earlier today" accordion) is being marked done and the
    // password gate is up. Kept separate from the two flags above because the live routine is the
    // evening one (currentState == ._EVENING_HABIT_), so passWordAuthenticated() can't tell this apart
    // by state — it dispatches on this flag + the stashed id instead.
    var passwordWindowShowingForPastHabit = false
    var pendingPastHabitId: String?
    var pendingPastHabitPerformedAt: Date?
    var actionBarItemPlay = "Play"
    var actionBarItemDone = "Done"
    var actionBarItemSkip = "Skip"
    var shouldIgnoreVisualizeInstructions = false
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
        var titleOfficeMode = "Office Mode"
        var titleWFHMode = "WFH Mode"
        btnEditHabits.title = "Customise my habits first"
        lblTitleSelectActivity.stringValue = "What 30 seconds of activity do you want to do?"
        lblTitleEnterActivityName.stringValue = "Enter name of activity"
        
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            lblTitleSelectActivity.stringValue = dic.value(forKey: "titleSelectActivity") as? String ?? lblTitleSelectActivity.stringValue
            lblTitleEnterActivityName.stringValue = dic.value(forKey: "titleEnterActivityName") as? String ?? lblTitleEnterActivityName.stringValue
            btnEditHabits.title = dic.value(forKey: "buttonEditHabitsText") as? String ?? btnEditHabits.title
        }
        textFieldActivity.delegate = self
        
        btnEditHabits.isSecondaryButton = true
        lblSelectHabits.isHidden = true
        boxNewBadge.isHidden = true
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            titleOfficeMode = menuInfo.value(forKey: "segmentOfficeModeText") as? String ?? titleOfficeMode
            titleWFHMode = menuInfo.value(forKey: "segmentWfhModeText") as? String ?? titleWFHMode
            toolTipOfficeMode = menuInfo.value(forKey: "toolTipOfficeMode") as? String ?? toolTipOfficeMode
            toolTipWfhMode = menuInfo.value(forKey: "toolTipWfhMode") as? String ?? toolTipWfhMode
        }
        
        segmentControlOfficeMode.selectedSegmentBezelColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        segmentControlOfficeMode.setLabel(titleOfficeMode, forSegment: 0)
        segmentControlOfficeMode.setLabel(titleWFHMode, forSegment: 1)
        
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            actionBarItemPlay = activityInfo.value(forKey: "actionBarItemPlay") as? String ?? actionBarItemPlay
            actionBarItemDone = activityInfo.value(forKey: "actionBarItemDone") as? String ?? actionBarItemDone
            actionBarItemSkip = activityInfo.value(forKey: "actionBarItemSkip") as? String ?? actionBarItemSkip
        }
        
        let boundsOfficeMode = NSRect(x: segmentControlOfficeMode.frame.minX, y: (segmentControlOfficeMode.frame.minY - 9), width: (segmentControlOfficeMode.frame.width/2) - 5, height: segmentControlOfficeMode.frame.height)
        let boundsWfhMode = NSRect(x: (segmentControlOfficeMode.frame.midX + 5), y: (segmentControlOfficeMode.frame.minY - 9), width: (segmentControlOfficeMode.frame.width/2) - 5, height: segmentControlOfficeMode.frame.height)// keep y to  egmentControlOfficeMode.frame.midY  do not change
        
        segmentOfficeModeTrackingArea = NSTrackingArea.init(rect: boundsOfficeMode, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        segmentControlOfficeMode.addTrackingArea(segmentOfficeModeTrackingArea!)
        
        segmentWfhModeTrackingArea = NSTrackingArea.init(rect: boundsWfhMode, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        segmentControlOfficeMode.addTrackingArea(segmentWfhModeTrackingArea!)

        // Schedule view: adds the "Schedule | Habits" tab over this habit-list screen.
        setupScheduleTab()
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
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == segmentOfficeModeTrackingArea{
            showTooltipWithOsTahoe(sender: segmentControlOfficeMode, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.minX, maxWidthVal:230, autoCloseOnMouseExit: true)
        }else if event.trackingArea == segmentWfhModeTrackingArea{
            showTooltipWithOsTahoe(sender: segmentControlOfficeMode, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == segmentOfficeModeTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == segmentWfhModeTrackingArea{
            closePopoverTooltipIfVisible()
        }
    }
    
    override func viewWillAppear() {
        boxSegmentControlOfficeMode.isHidden = true
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
            imgViewTopSpace.constant = 10
            imgViewBottomSpace.constant = 5
            lblSubTitle.isHidden = false
            tblViewHabits.isHidden = true
            scrollViewHabits.isHidden = true
            btnBottomSpace.constant = 63
            btnTopSpace.constant = 171
            btnTopSpaceValue = 171
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
                // Schedule redesign: collapse the decorative header image + top spacer that
                // left a large gap above the habit list.
                btnTopSpace.constant = 12
                btnTopSpaceValue = 12
                imgView.image = nil
                imgViewHeight.constant = 0
                imgViewTopSpace.constant = 0
                imgViewBottomSpace.constant = 0
                lblTitle.stringValue = startMorningHabitTitleText
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                preloadVisualizeInstructionsOnNextTurn()
                
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
                btnTopSpace.constant = 12
                btnTopSpaceValue = 12
                btnBottomSpace.constant = 100
                imgView.image = nil
                imgViewHeight.constant = 0
                imgViewTopSpace.constant = 0
                imgViewBottomSpace.constant = 0
                lblTitle.stringValue = startEveningHabitTitleText
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                preloadVisualizeInstructionsOnNextTurn()
            }else if currentState == ._MICRO_BREAK_{
                // The break start screen moved to breakStartVc (SwiftUI), which habitsVc shows
                // instead of this one, so this branch no longer renders the break list. Kept because
                // this controller is still shown in other states and can be reached mid-break.
                boxSegmentControlOfficeMode.isHidden = false
                btnSelectHabitsToDo.isHidden = true
                btnEditHabits.isHidden = true
                btnPostponeBreak.isHidden = false
                lblProgress.isHidden = false
                lblSelectHabits.isHidden = true
                
                btnPostponeBreak.title = "Skip this habit for today"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnPostponeBreak.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnPostponeBreak.title
                }
                
                lblTitle.stringValue = activityCompletionVcObj?.lblTitle.stringValue ?? ""
                // When the micro-break list first renders, activityCompletionVcObj's title can
                // still be empty (it's only populated once the break activity screen is built),
                // which left the list header blank. Fall back to computing the start-break title
                // from the first activity, mirroring activityCompletionVc.startBreakActivity().
                if lblTitle.stringValue.isEmpty, !arrFinalBreakActivities.isEmpty,
                   let currentActivity = arrFinalBreakActivities[0].activity {
                    let activityName: String
                    if currentActivity.choiceType != ._RANDOM_ {
                        activityName = currentActivity.name
                    } else {
                        activityName = arrFinalBreakActivities[0].randomChoice?.name ?? ""
                    }
                    lblTitle.stringValue = getStartBreakActivityTitleText(seconds: currentActivity.durationSeconds, activityName: activityName)
                }
                btnStartFirstHabit.title = activityCompletionVcObj?.btnMain.title ?? ""
                
                lblProgress.stringValue = activityCompletionVcObj?.lblProgress.stringValue ?? ""
                
                btnTopSpace.constant = 60
                btnTopSpaceValue = 60
                btnBottomSpace.constant = 100
                imgView.image = nil
                imgViewHeight.constant = 40
                imgViewTopSpace.constant = 35
                imgViewBottomSpace.constant = 5
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                if SettingsManagerObject.isOfficeModeEnabled{
                    segmentControlOfficeMode.setSelected(true, forSegment: 0)
                }else{
                    segmentControlOfficeMode.setSelected(true, forSegment: 1)
                }
                startMicroBreakTimer(duration: 5)
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
                btnTopSpaceValue = 60
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
                preloadVisualizeInstructionsOnNextTurn()
                
            }
        }
        resetFrame()
    }
    
    /// Pre-warm the Visualize step (its storyboard scene, WKWebView included, plus the motivational-message
    /// page load) on the NEXT main-queue turn instead of inline. viewWillAppear runs inside the routine-start
    /// turn (startHabitsCall → showAllMorningHabits → addSubview), which already builds this screen and the
    /// edit-routine scene; loading a third scene here too pushed that turn past the 2 s hang threshold
    /// (FOCUS-BEAR-MACOS-1CC). Nothing touches the Visualize step before the user clicks Start, and that
    /// click can't be processed before this block runs.
    private func preloadVisualizeInstructionsOnNextTurn() {
        DispatchQueue.main.async {
            let visualizeInstructions = getvisualizeInstructionsObject()
            if !visualizeInstructions.isViewLoaded {
                visualizeInstructions.loadView()
            }
            visualizeInstructions.tryPreLoadMotivationalMessage()
        }
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
    
    override func viewDidAppear() {
        // viewWillAppear re-shows the habit list every time this view appears; re-hide it whenever
        // the Day Plan is the front content. A visible-but-occluded table keeps firing its cells'
        // activeAlways tracking areas (stray hand cursor) and stays hit-testable (clicks fall
        // through and start the selected habit). updateScheduleTabForState only ran on state
        // changes, so a plain navigate-back to the Day Plan left the list live underneath.
        updateScheduleTabForState()
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
                        if self.view.window != nil{
                            self.presentAsSheet(getImpactMeasurementVcObject())
                            isAnyNagVisible = true
                        }
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
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here
        if imgView.image != nil{
            imgViewHeight.constant = self.view.frame.height / 7
        }
        resetFrame()
    }
    
    func resetFrame(){
        if self.view.frame.height < 600{
            lblTitle.font = NSFont.systemFont(ofSize: 20)
            btnTopSpace.constant = btnTopSpaceValue - 40
            heightBoxScrollView.constant = 120
        }else if self.view.frame.height < 700{
            lblTitle.font = NSFont.systemFont(ofSize: 30)
            btnTopSpace.constant = btnTopSpaceValue - 25
            heightBoxScrollView.constant = 155
        }else if self.view.frame.height < 800{
            lblTitle.font = NSFont.systemFont(ofSize: 35)
            btnTopSpace.constant = btnTopSpaceValue - 15
            heightBoxScrollView.constant = 165
        }else if self.view.frame.height < 900{
            lblTitle.font = NSFont.systemFont(ofSize: 40)
            btnTopSpace.constant = btnTopSpaceValue
            heightBoxScrollView.constant = 180
        }else{
            lblTitle.font = NSFont.systemFont(ofSize: 40)
            btnTopSpace.constant = btnTopSpaceValue
            heightBoxScrollView.constant = 180
        }
    }
    
    var limitedUsageViewNagShownOnce = false
    func showLimitedUsgaeViewIfNeeded(){// after 7 trial days
        if limitedUsageViewNagShownOnce{
            return;// doing this so that it is shown only once per app session
        }
        if isExpired && isActivitiesReducedInExpiredApp{
            if alertLimitedUsageVcObj != nil{
                if alertLimitedUsageVcObj?.presentingViewController != self{
                    allApiObject.capturePosthog(event: "alert-limited-usage-shown", metadata: [:])
                    if self.view.window != nil{
                        limitedUsageViewNagShownOnce = true
                        self.presentAsSheet(getAlertLimitedUsageVcObject())
                    }
                }
            }else{
                allApiObject.capturePosthog(event: "alert-limited-usage-shown", metadata: [:])
                if self.view.window != nil{
                    limitedUsageViewNagShownOnce = true
                    self.presentAsSheet(getAlertLimitedUsageVcObject())
                }
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
                    if self.view.window != nil{
                        self.presentAsSheet(getLateMorningHabitPopupVcObject())
                    }
                }
            }
        }
    }
    
    // Kept as a no-op for the existing onboarding/upgrade completion callbacks.
    // Routine duration is now managed in the Day Plan, without a startup interruption.
    func showConfirmRoutineDurationViewIfNeeded() {}

    func startMicroBreakTimer(duration:Int) {
        if isTimerGoingOn{
            lbltimer.isHidden = false
            return
        }
        lbltimer.isHidden = false
        isTimerGoingOn = true
        currentTimer = 0
        totalDuration = duration
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lbltimer.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performMicroBreakTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func performMicroBreakTimerCount() {
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lbltimer.isHidden = false
            self.lbltimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.main.async { [self] in
                self.isTimerGoingOn = false
                self.lbltimer.isHidden = true
                btnStartFirstHabitClicked(self)
            }
        }
    }
    
    func stopTimer(){
        self.timer?.invalidate()
        self.lbltimer.isHidden = true
        self.isTimerGoingOn = false
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
            getHabitsVcObject().abortCurrentState()
            return;
        }
        activityCompletionVcObj?.btnSkipHabitClicked(self)//for breakActivity only
    }
    
    
    @IBAction func btnEditHabitsClicked(_ sender: Any) {
        passwordWindowShowingForMarkHabitComplete = false
        passwordWindowShowingForMarkHabitSkip = false
        passwordWindowShowingForPastHabit = false
        if shouldAskPassword(){
            if SettingsManagerObject.isPasswordRequireInChangeSettings{
                getHabitsVcObject().showPasswordView()
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
    
    func passWordAuthenticated(){
        // #2012: a past habit (morning or evening) was gated (checked first — the live routine is the evening one,
        // so the state-based branches below can't distinguish it).
        if passwordWindowShowingForPastHabit {
            passwordWindowShowingForPastHabit = false
            if let id = pendingPastHabitId {
                let performedAt = pendingPastHabitPerformedAt ?? Date()
                pendingPastHabitId = nil; pendingPastHabitPerformedAt = nil
                performPastHabitCompletion(id: id, performedAt: performedAt)
            }
            return
        }
        if passwordWindowShowingForMarkHabitComplete{
            if currentState == ._MORNING_HABIT_{
                morningHabitAlreadyDoneClicked()
            }else if currentState == ._EVENING_HABIT_{
                eveningHabitAlreadyDoneClicked()
            }
        }else if passwordWindowShowingForMarkHabitSkip{
            if currentState == ._MORNING_HABIT_{
                tryMorningRoutineSkip()
            }else if currentState == ._EVENING_HABIT_{
                tryEveningRoutineSkip()
            }
        }else{
            showEditHabitsView()
        }
    }
    
    
    func tryMorningRoutineSkip(){
        if SettingsManagerObject.isEasySkipEnabled{
            self.morningHabitSkipClicked()
        }else{
            mainViewControllerObj!.showOneClickSkipHabitView(completionHandler: {
                self.morningHabitSkipClicked()
            })
        }
    }
    
    func tryEveningRoutineSkip(){
        if SettingsManagerObject.isEasySkipEnabled{
            self.eveningHabitSkipClicked()
        }else{
            mainViewControllerObj!.showOneClickSkipHabitView(completionHandler: {
                self.eveningHabitSkipClicked()
            })
        }
    }
    func sortMorningHabitsBySelectedFirst(){
        // The table view outlet can be nil here when this is reached
        // programmatically (e.g. scheduleStart -> btnStartFirstHabitClicked)
        // before/after the view is in the hierarchy, which previously crashed
        // with an implicit-unwrap nil. Also bounds-check the selected row
        // against the backing array. See Sentry FOCUS-BEAR-MACOS-10S.
        guard let tblViewHabits = tblViewHabits else { return }
        let selectedRow = tblViewHabits.selectedRow
        if selectedRow > 0 && selectedRow < arrFilteredMorningHabits.count{
            var tempArr = arrFilteredMorningHabits
            arrFilteredMorningHabits.removeAll()
            arrFilteredMorningHabits.append(tempArr[selectedRow])
            tempArr.remove(at: selectedRow)
            for item in tempArr{
                arrFilteredMorningHabits.append(item)
            }
        }
    }
    
    @IBAction func btnStartFirstHabitClicked(_ sender: Any) {
        addLog(text: "[user-action] btnStartFirstHabitClicked")
        self.timer?.invalidate()
        self.isTimerGoingOn = false
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
            if enterPasswordVcObj != nil{
                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                    return;
                }
            }
        }
        if isFirstTime{
            getHabitsVcObject().startBreathing()
        }else{
            if currentState == ._MORNING_HABIT_{
                sortMorningHabitsBySelectedFirst()
                currentHabitIndex = -1
                // Once per routine per day: the in-memory flag alone let a restart show the
                // motivation prompt again (report 2026-09-13_20-30-50).
                if shouldIgnoreVisualizeInstructions || !RoutineVisualizePrompt.shouldShow(for: .morning) {
                    getHabitsVcObject().startFirstMorningHabit()
                }else{
                    getHabitsVcObject().showVisualizeInstructionsVc()
                    visualizeInstructionsVcObj?.startTimer()
                    RoutineVisualizePrompt.markShown(for: .morning)
                    allApiObject.capturePosthog(event: "visualize-morning-routine", metadata: ["routine-type":"morning_routine"])
                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsBeginMorningHabitClickedDate)
                }
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

                if shouldIgnoreVisualizeInstructions || !RoutineVisualizePrompt.shouldShow(for: .evening) {
                    getHabitsVcObject().startFirstEveningHabit()
                }else{
                    getHabitsVcObject().showVisualizeInstructionsVc()
                    visualizeInstructionsVcObj?.startTimer()
                    RoutineVisualizePrompt.markShown(for: .evening)
                    allApiObject.capturePosthog(event: "visualize-evening-routine", metadata: ["routine-type":"evening_routine"])
                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsBeginEveningHabitClickedDate)
                }
            }else if currentState == ._MICRO_BREAK_{
                activityCompletionVcObj?.btnMainClicked(self)
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
                currentHabitIndex = -1
                let routine = RoutineVisualizePrompt.Routine.custom(arrAllCustomRoutine.indices.contains(currentRoutineIndex)
                                                                   ? arrAllCustomRoutine[currentRoutineIndex].sequenceId
                                                                   : "\(currentRoutineIndex)")
                if shouldIgnoreVisualizeInstructions || !RoutineVisualizePrompt.shouldShow(for: routine) {
                    getHabitsVcObject().startFirstCustomRoutineHabit()
                } else {
                    getHabitsVcObject().showVisualizeInstructionsVc()
                    visualizeInstructionsVcObj?.startTimer()
                    RoutineVisualizePrompt.markShown(for: routine)
                    allApiObject.capturePosthog(event: "visualize-morning-routine", metadata: ["routine-type":"custom_routine"])
                }
            }
        }
    }
    
    @IBAction func btnSelectHabitsToDoClicked(_ sender: Any) {
        showChooseHabitsView()
    }
    
    func showChooseHabitsView(){
        addLog(text: "showChooseHabitsView")
        currentHabitIndex = -1
        if self.view.window != nil{
            if chooseHabitsVCObj == nil{
                chooseHabitsVCObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("chooseHabitsVC")) as? chooseHabitsVC
            }
            chooseHabitsVCObj!.currentHabitIndex = currentHabitIndex
            chooseHabitsVCObj!.openedFromDayPlan = false   // default; the Day Plan path sets it true after
            self.presentAsSheet(chooseHabitsVCObj!)
        }
    }

    @IBAction func segmentControlOfficeModeClicked(_ sender: Any) {
        addLog(text:"[user-action] firstViewController:- btnEnableOfficeModeClicked")
        
        if SettingsManagerObject.isOfficeModeEnabled{
            SettingsManagerObject.isOfficeModeEnabled = false
            NSApplication.shared.applicationIconImage = nil
            allApiObject.capturePosthog(event: "disable-office-mode", metadata: [:])
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
            segmentControlOfficeMode.setSelected(true, forSegment: 1)
            getHabitsVcObject().reFillBreakActivitiesArray()
            tblViewHabits.reloadData()
            //v 2.27.422
            activityCompletionVcObj?.startBreakActivity()
            btnStartFirstHabit.title = activityCompletionVcObj?.btnMain.title ?? ""
            lblProgress.stringValue = activityCompletionVcObj?.lblProgress.stringValue ?? ""
        }else{
            let filterArr = arrAllbreakActivities.filter { $0.isOfficeFriendly == true}
            if filterArr.count == 0{// no activity found with isOfficeFriendly //
                let alert = NSAlert()
                alert.setSharingType()
                var noOfficeFriendlyActivityAlertText = "You don't have any office friendly break activities. Do you want me to add one for you to stand up and stretch for 20 seconds?"
                var noOfficeFriendlyActivityButtonFirstText = "Yeah sounds good"
                var noOfficeFriendlyActivityButtonSecondText = "No I'm a machine! I don't need breaks"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    noOfficeFriendlyActivityAlertText = menuInfo.value(forKey: "noOfficeFriendlyActivityAlertText") as? String ?? noOfficeFriendlyActivityAlertText
                    noOfficeFriendlyActivityButtonFirstText = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonFirstText") as? String ?? noOfficeFriendlyActivityButtonFirstText
                    noOfficeFriendlyActivityButtonSecondText = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonSecondText") as? String ?? noOfficeFriendlyActivityButtonSecondText
                }
                alert.messageText = noOfficeFriendlyActivityAlertText//
                alert.addButton(withTitle: noOfficeFriendlyActivityButtonFirstText)
                alert.addButton(withTitle: noOfficeFriendlyActivityButtonSecondText)
                NSApplication.shared.activate(ignoringOtherApps: true)
                alert.beginSheetModal(for: self.view.window!,completionHandler: {result in
                    if result == .alertFirstButtonReturn{
                        print("first button")
                        menuViewControllerObj?.addOfficeFriendlyActivityInSettings()
                        self.enableOfficeMode()
                    }else{
                        print("second button")
                        if SettingsManagerObject.isOfficeModeEnabled{
                            self.segmentControlOfficeMode.setSelected(true, forSegment: 0)
                        }else{
                            self.segmentControlOfficeMode.setSelected(true, forSegment: 1)
                        }
                    }
                })
            }else{
                enableOfficeMode()
                
            }
            
        }
        
    }
    func enableOfficeMode(){
        addLog(text: "enableOfficeMode")
        if UserDefaults.standard.object(forKey: "officeModeEnabledSuccessAlertShown") == nil{
            let alert = NSAlert()
            alert.setSharingType()
            var officeModeEnabledSuccessfullyText = "Ok! I'll just prompt you to do activities that won't weird other people out (doing handstand pushups in the office might raise a few eyebrows)."
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                officeModeEnabledSuccessfullyText = menuInfo.value(forKey: "officeModeEnabledSuccessfullyText") as? String ?? officeModeEnabledSuccessfullyText
            }
            alert.messageText = officeModeEnabledSuccessfullyText
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            UserDefaults.standard.set(true, forKey: "officeModeEnabledSuccessAlertShown")
        }
        
        
        SettingsManagerObject.isOfficeModeEnabled = true
        allApiObject.capturePosthog(event: "enable-office-mode", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
        segmentControlOfficeMode.setSelected(true, forSegment: 0)
        NSApplication.shared.applicationIconImage = NSImage(named: NSImage.Name("Bear-Office-icon"))
        getHabitsVcObject().reFillBreakActivitiesArray()
        tblViewHabits.reloadData()
        
        //v 2.27.422
        activityCompletionVcObj?.startBreakActivity()
        btnStartFirstHabit.title = activityCompletionVcObj?.btnMain.title ?? ""
        lblProgress.stringValue = activityCompletionVcObj?.lblProgress.stringValue ?? ""
    }
    
    func morningHabitAlreadyDoneClicked(){
        addLog(text: "action bar:- morningHabitAlreadyDoneClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex]
        if arrFilteredMorningHabits[currentHabitIndex].useTimer{
            habitTotalCompletedSeconds += lastHabit.durationSeconds!
        }
        lastActivityPerformedTime = Date()
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredMorningHabits[lastHabitIndex])
        
        if arrFilteredMorningHabits.count == 1{
            habitsVcObj?.showThirdVc()
            activityCompletionVcObj!.showLastMorningHabitFinishedViewFromActionbar(index: lastHabitIndex, isSkipped: false)
        }else{
            arrFilteredMorningHabits.remove(at: currentHabitIndex) // dont remove if last index
            if let index = arrPreFilteredMorningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
                arrPreFilteredMorningHabits.remove(at: index)
            }
            tblViewHabits.reloadData()
        }
        
        if lastHabit.logQuantity{
            
            getHabitsVcObject().showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            logQuantityVcObj?.resetData(name: lastHabit.name, durationInSeconds: "\(duration)", logQuantityQuestion: lastHabit.logQuantityQuestion, currentState: ._MORNING_HABIT_, logQuantityType: "", activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, take_notes: lastHabit.take_notes, notes: "", logQuantityQuestions: lastHabit.logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "morning routine", activity: lastHabit.name, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            if lastHabit.take_notes == END_OF_ACTIVITY{
                getHabitsVcObject().showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else{
                allApiObject.activityCompletedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
        }
        
        //focusButtonService-------//
        focusButtonServiceObject.sendMorningHabitsToFocusDevice()
        //---------//
    }

    /// Mark a PAST morning habit (surfaced in the Day Plan's "Show events from earlier today" accordion)
    /// as done **by id**, without disturbing the live (evening) routine — per Prashant's #2012 design.
    /// There is deliberately no Skip: a habit sitting un-struck in the earlier-today section is *already*
    /// evidently un-done, so the only useful action is "actually, I did do this".
    ///
    /// Completing a historical habit is a cheat vector (asserting you did something you didn't), so it
    /// honours the same password rule as skipping a morning habit (isPasswordRequireInSkipMorning).
    /// After the gate, `performPastHabitCompletion` runs the real completion — through the
    /// log-quantity / notes popups when the habit has them, exactly like the live "already done" action.
    /// Handles both morning and evening past habits (looked up by id in either all-days list); the skip
    /// password rule follows the habit's own routine.
    func completePastHabit(id: String, performedAt: Date) {
        addLog(text: "action bar (past habit):- completePastHabit id=\(id) performedAt=\(performedAt)")
        let isEvening = arrAllDaysMorningHabits.first(where: { $0.id == id }) == nil
            && arrAllDaysEveningHabits.contains(where: { $0.id == id })
        let skipPasswordRequired = isEvening ? SettingsManagerObject.isPasswordRequireInSkipEvening
                                             : SettingsManagerObject.isPasswordRequireInSkipMorning
        if shouldAskPassword() && skipPasswordRequired {
            passwordWindowShowingForMarkHabitComplete = false
            passwordWindowShowingForMarkHabitSkip = false
            passwordWindowShowingForPastHabit = true
            pendingPastHabitId = id
            pendingPastHabitPerformedAt = performedAt
            mainViewControllerObj?.showPasswordView()
            enterPasswordVcObj?.parentVc = self
        } else {
            performPastHabitCompletion(id: id, performedAt: performedAt)
        }
    }

    /// The actual by-id completion of a past habit — morning OR evening. Mirrors the live "I already
    /// did this" action (its log-quantity / take-notes popups and `is_skipped: true` "already done"
    /// semantics), but WITHOUT the active-routine coupling: it never indexes into / mutates the
    /// `arrFiltered*` arrays, never pushes thirdVc / activityCompletion, and forces
    /// `should_not_update_current_activity: true` (via the popups' `isPastHabit` flag, or directly) so
    /// the running routine is untouched. Looks the habit up in `arrAllDaysMorningHabits` /
    /// `arrAllDaysEveningHabits` (survives array clearing / skip-for-today).
    func performPastHabitCompletion(id: String, performedAt: Date) {
        let morningHabit = arrAllDaysMorningHabits.first(where: { $0.id == id })
        guard let habit = morningHabit ?? arrAllDaysEveningHabits.first(where: { $0.id == id }) else { return }
        addLog(text: "action bar (past habit):- performPastHabitCompletion id=\(id) performedAt=\(performedAt) evening=\(morningHabit == nil)")
        // Backdate the completion to the habit's slot on the viewed day so the backend records it against
        // the right date (via /completed-activity's start_time/finish_time — the same fields the offline
        // activity-sync replays). dayKey drives the local per-day strike-through.
        lastActivityPerformedTime = performedAt
        let dayKey = getStringFromDate(date: performedAt, dateFormat: "yyyy-MM-dd")
        let duration = getLastHabitDoneDuration(lastHabit: habit)

        if habit.logQuantity {
            // Present on the Day Plan's own visible view (this VC), NOT habitsVc — the routine player is
            // hidden behind the Day Plan when completing a past habit, so showLogQuantityView() (which
            // attaches there) would put the popup off-screen and it'd look like nothing happened.
            presentPastHabitPopup(logQuantityVcObj?.view)
            logQuantityVcObj?.isReviseQuantity = false
            logQuantityVcObj?.resetData(name: habit.name, durationInSeconds: "\(duration)",
                                        logQuantityQuestion: habit.logQuantityQuestion,
                                        currentState: morningHabit == nil ? ._EVENING_HABIT_ : ._MORNING_HABIT_, logQuantityType: "",
                                        activity_id: habit.id, activity_sequence_id: habit.activity_sequence_id,
                                        activityChoiceId: nil, take_notes: habit.take_notes, notes: "",
                                        logQuantityQuestions: habit.logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true          // "already done" marker, matching the live flow
            logQuantityVcObj?.isPastHabit = true         // forces should_not_update + marks the Day Plan done
            logQuantityVcObj?.pastHabitId = habit.id
            logQuantityVcObj?.pastHabitDayKey = dayKey
        } else if habit.take_notes == END_OF_ACTIVITY {
            // takeActivityNotesVcObj is a LAZY optional (nil until first use) — unlike the eagerly-created
            // logQuantityVcObj above — so instantiate it here via its getter. Otherwise its .view is nil,
            // presentPastHabitPopup(nil) silently no-ops and the notes screen never appears. (The live
            // path relies on showTakeNotesView() to create it, but that attaches it to the routine
            // player, which is hidden behind the Day Plan when completing a past habit.)
            let notesVc = getTakeActivityNotesVcObj()
            presentPastHabitPopup(notesVc.view)
            notesVc.resetData(durationInSeconds: duration, quantity_logged: nil,
                              activity_id: habit.id, activity_sequence_id: habit.activity_sequence_id,
                              activityChoiceId: nil, log_quantity_answers: [])
            notesVc.is_skipped = true
            notesVc.isPastHabit = true
            notesVc.pastHabitId = habit.id
            notesVc.pastHabitDayKey = dayKey
        } else {
            recordPastHabitCompletionViaOfflineSync(
                activity_id: habit.id, activity_sequence_id: habit.activity_sequence_id,
                performedAt: performedAt, duration: duration, quantity: nil, notes: "", dayKey: dayKey)
        }
    }

    /// Add a log-quantity / take-notes popup over the Day Plan so it's visible when completing a PAST
    /// habit — the normal showLogQuantityView()/showTakeNotesView() attach to the routine-player view
    /// (habitsVc), which is hidden behind the Day Plan, so the popup rendered off-screen. Present it on
    /// the WINDOW's content view (the top-most visible container) so it's always on top. The popups
    /// remove themselves from their superview on OK/Cancel.
    private func presentPastHabitPopup(_ popupView: NSView?) {
        guard let popupView = popupView else {
            addLog(text: "past-habit popup: view was nil — cannot present")
            return
        }
        popupView.removeFromSuperview()   // detach if it was still attached to habitsVc from a live use
        // Present on the KEY window's content view — the front-most visible container regardless of which
        // Day Plan host (firstViewController / routinePostponedInfoVc / habitsStateVc) is on screen.
        let host = NSApp.keyWindow?.contentView ?? view.window?.contentView ?? mainViewControllerObj?.view ?? view
        addLog(text: "past-habit popup: presenting on \(NSApp.keyWindow != nil ? "keyWindow" : "fallback")")
        host.addSubview(popupView)
        host.addConstraints(subView: popupView)
    }

    func eveningHabitAlreadyDoneClicked(){
        addLog(text: "action bar:- eveningHabitAlreadyDoneClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex]
        if arrFilteredEveningHabits[currentHabitIndex].useTimer{
            habitTotalCompletedSeconds += lastHabit.durationSeconds!
        }
        lastActivityPerformedTime = Date()
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredEveningHabits[lastHabitIndex])
        
        
        if arrFilteredEveningHabits.count == 1{
            habitsVcObj?.showThirdVc()
            activityCompletionVcObj!.showLastEveningHabitFinishedViewFromActionbar(index: lastHabitIndex, isSkipped: false)
        }else{
            arrFilteredEveningHabits.remove(at: currentHabitIndex)
            if let index = arrPreFilteredEveningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
                arrPreFilteredEveningHabits.remove(at: index)
            }
            tblViewHabits.reloadData()
        }
        if lastHabit.logQuantity{
            
            getHabitsVcObject().showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            logQuantityVcObj?.resetData(name: lastHabit.name, durationInSeconds: "\(duration)", logQuantityQuestion: lastHabit.logQuantityQuestion, currentState: ._EVENING_HABIT_, logQuantityType: "", activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, take_notes: lastHabit.take_notes, notes: "", logQuantityQuestions: lastHabit.logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "evening routine", activity: lastHabit.name, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            if lastHabit.take_notes == END_OF_ACTIVITY{
                getHabitsVcObject().showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else{
                allApiObject.activityCompletedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
        }
        //focusButtonService-------//
        focusButtonServiceObject.sendEveningHabitsToFocusDevice()
        //---------//
    }
    
    func customHabitAlreadyDoneClicked(){
        addLog(text: "action bar:- customHabitAlreadyDoneClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[lastHabitIndex]
        if lastHabit.useTimer{
            habitTotalCompletedSeconds += lastHabit.durationSeconds!
        }
        lastActivityPerformedTime = Date()
        let duration = getLastHabitDoneDuration(lastHabit: lastHabit)
        
        
        if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count == 1{
            habitsVcObj?.showThirdVc()
            activityCompletionVcObj!.showLastCustomRoutineHabitFinishedViewFromActionbar(index: lastHabitIndex, isSkipped: false)
        }else{
            arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: currentHabitIndex)
            if let index = arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits.firstIndex(where: { $0.id == lastHabit.id }) {
                arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits.remove(at: index)
            }
            tblViewHabits.reloadData()
        }
        if lastHabit.logQuantity{
            
            getHabitsVcObject().showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            logQuantityVcObj?.resetData(name: lastHabit.name, durationInSeconds: "\(duration)", logQuantityQuestion: lastHabit.logQuantityQuestion, currentState: ._CUSTOM_ROUTINE_, logQuantityType: "", activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, take_notes: lastHabit.take_notes, notes: "", logQuantityQuestions: lastHabit.logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "custom routine", activity: lastHabit.name, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            if lastHabit.take_notes == END_OF_ACTIVITY{
                getHabitsVcObject().showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else{
                allApiObject.activityCompletedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
        }
    }
    
    func morningHabitSkipClicked(){
        addLog(text: "action bar:- morningHabitSkipClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex]
        lastActivityPerformedTime = Date()
        
        if arrFilteredMorningHabits.count == 1{
            habitsVcObj?.showThirdVc()
            activityCompletionVcObj!.showLastMorningHabitFinishedViewFromActionbar(index: lastHabitIndex, isSkipped: true)
        }else{
            arrFilteredMorningHabits.remove(at: currentHabitIndex) // dont remove if last index
            if let index = arrPreFilteredMorningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
                arrPreFilteredMorningHabits.remove(at: index)
            }
            tblViewHabits.reloadData()
        }
        allApiObject.activitySkippedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, completionHandler: {dic in

        })
        //focusButtonService-------//
        focusButtonServiceObject.sendMorningHabitsToFocusDevice()
        //---------//
        // Optimistic Day Plan update: the habit is already gone from arrFilteredMorningHabits above, so
        // refresh the schedule now instead of waiting ~10s for the next server-driven refresh tick.
        if let id = lastHabit.id { dayPlanCompletedHabitIds.insert(id) }
        refreshScheduleIfVisible()
    }
    
    func eveningHabitSkipClicked(){
        addLog(text: "action bar:- eveningHabitSkipClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex]
        lastActivityPerformedTime = Date()
        
        if arrFilteredEveningHabits.count == 1{
            habitsVcObj?.showThirdVc()
            activityCompletionVcObj!.showLastEveningHabitFinishedViewFromActionbar(index: lastHabitIndex, isSkipped: true)
        }else{
            arrFilteredEveningHabits.remove(at: currentHabitIndex) // dont remove if last index
            if let index = arrPreFilteredEveningHabits.firstIndex(where: { $0.id == lastHabit.id }) {
                arrPreFilteredEveningHabits.remove(at: index)
            }
            tblViewHabits.reloadData()
        }
        allApiObject.activitySkippedApi(activity_id: lastHabit.id, activity_sequence_id: lastHabit.activity_sequence_id, completionHandler: {dic in

        })
        //focusButtonService-------//
        focusButtonServiceObject.sendEveningHabitsToFocusDevice()
        //---------//
        // Optimistic Day Plan update (see morningHabitSkipClicked).
        if let id = lastHabit.id { dayPlanCompletedHabitIds.insert(id) }
        refreshScheduleIfVisible()
    }
    
    func customRoutineHabitSkipClicked(){
        addLog(text: "action bar:- customRoutineHabitSkipClicked")
        let lastHabitIndex = currentHabitIndex
        let lastHabit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[lastHabitIndex]
        lastActivityPerformedTime = Date()
        
        if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count == 1{
            habitsVcObj?.showThirdVc()
            activityCompletionVcObj!.showLastCustomRoutineHabitFinishedViewFromActionbar(index: lastHabitIndex, isSkipped: true)
        }else{
            arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: currentHabitIndex)
            if let index = arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits.firstIndex(where: { $0.id == lastHabit.id }) {
                arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits.remove(at: index)
            }
            tblViewHabits.reloadData()
        }
        // Optimistic Day Plan update (see morningHabitSkipClicked).
        if let id = lastHabit.id { dayPlanCompletedHabitIds.insert(id) }
        refreshScheduleIfVisible()
    }
}
extension firstViewController:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if currentState == ._MORNING_HABIT_{
            return  arrFilteredMorningHabits.count
        }else if currentState == ._EVENING_HABIT_{
            return  arrFilteredEveningHabits.count
        }else if currentState == ._MICRO_BREAK_{
            return  arrFinalBreakActivities.count
        }else if currentState == ._CUSTOM_ROUTINE_{
            return  arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count
        }else{
            return 0
        }
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // AppKit can ask for a row that no longer matches our backing arrays
        // (e.g. while the habit list is re-sorted/cleared during scheduleStart,
        // before reloadData catches up), which previously crashed with
        // "Index out of range". numberOfRows(in:) is the source of truth for
        // the current state's array. See Sentry FOCUS-BEAR-MACOS-10W.
        guard row >= 0 && row < numberOfRows(in: tableView) else {
            return NSTableCellView()
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            cell.boxBg.fillColor = NSColor.clear
            cell.lblTitle.textColor = NSColor.labelColor
            if currentState == ._MORNING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredMorningHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.orange
                    cell.lblTitle.textColor = NSColor.white
                }
            }else if currentState == ._EVENING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredEveningHabits[row].name ?? "")"
                cell.boxBg.borderColor = NSColor.clear
                cell.lblTitle.tag = 99
                if tblViewHabits.selectedRow == row{
                    cell.boxBg.fillColor = NSColor.orange
                    cell.lblTitle.textColor = NSColor.white
                }
            }else if currentState == ._MICRO_BREAK_{
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
                    cell.boxBg.fillColor = NSColor.orange
                    cell.lblTitle.textColor = NSColor.white
                }
            }
            
            cell.boxBg.wantsLayer = true
            cell.boxBg.layer?.borderWidth = 1
            cell.boxBg.layer?.cornerRadius = 7
            
            if row == tblViewHabits.selectedRow{
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
                    cell.boxBg.layer?.borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.blue.cgColor
                }
                addActionBar(cell: cell, row: row)
            }else{
                cell.boxActionBar.isHidden = true
                cell.boxBg.layer?.borderColor = .clear
            }
            
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func addActionBar(cell: tblCellHabits, row:Int){
        if cell.lblTitle.tag == 99{
            cell.boxActionBar.isHidden = false
            cell.stackViewActionBar.subviews.removeAll()
            
            let itemPlay = getItemActionBarPlayVcObject()
            if !itemPlay.isViewLoaded{
                itemPlay.loadView()
            }
            itemPlay.lblTitle.stringValue = actionBarItemPlay
            itemPlay.imgView.image = NSImage(named: NSImage.touchBarPlayTemplateName)
            itemPlay.btnMain.target = self
            itemPlay.btnMain.tag = row
            itemPlay.btnMain.action = #selector(btnPlayClicked)
            itemPlay.boxBtn.fillColor = NSColor.orange
            itemPlay.imgView.contentTintColor = NSColor.white
            cell.stackViewActionBar.addView(itemPlay.view, in: .bottom)
            
            let itemDone = getItemActionBarDoneVcObject()
            if !itemDone.isViewLoaded{
                itemDone.loadView()
            }
            itemDone.lblTitle.stringValue = actionBarItemDone
            itemDone.imgView.image = NSImage(named: NSImage.menuOnStateTemplateName)
            itemDone.btnMain.target = self
            itemDone.btnMain.tag = row
            itemDone.btnMain.action = #selector(btnDoneClicked)
            cell.stackViewActionBar.addView(itemDone.view, in: .bottom)
            
            let itemSkip = getItemActionBarSkipVcObject()
            if !itemSkip.isViewLoaded{
                itemSkip.loadView()
            }
            itemSkip.lblTitle.stringValue = actionBarItemSkip
            itemSkip.imgView.image = NSImage(named: NSImage.touchBarFastForwardTemplateName)
            itemSkip.btnMain.target = self
            itemSkip.btnMain.tag = row
            itemSkip.btnMain.action = #selector(btnSkipClicked)
            cell.stackViewActionBar.addView(itemSkip.view, in: .bottom)
            
            cell.isSelected = tblViewHabits.selectedRow == row
        }else{
            cell.boxActionBar.isHidden = true
        }
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
                    cell.boxActionBar.isHidden = true
                    cell.isSelected = false
                    cell.boxBg.layer?.borderColor = NSColor.clear.cgColor
                }
            }
            
            if let cell = tblViewHabits.view(atColumn: 0, row: tblViewHabits.selectedRow, makeIfNecessary: true) as? tblCellHabits{
                cell.boxBg.fillColor = NSColor.orange
                cell.lblTitle.textColor = NSColor.white
                cell.isSelected = true
                cell.boxBg.layer?.borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.blue.cgColor
                addActionBar(cell: cell, row: tblViewHabits.selectedRow)
            }
        }
        
        if currentState == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                let time = arrFilteredMorningHabits[tblViewHabits.selectedRow].durationSeconds!
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredMorningHabits[tblViewHabits.selectedRow].name!)
            }
        }else if currentState == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                let time = arrFilteredEveningHabits[tblViewHabits.selectedRow].durationSeconds!
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[tblViewHabits.selectedRow].name!)
            }
        }
    }
    
    @objc func btnPlayClicked(sender: NSButton){
        addLog(text: "action bar:- btnPlayClicked")
        btnStartFirstHabitClicked(self)
    }
    
    @objc func btnDoneClicked(sender: NSButton){
        addLog(text: "action bar:- btnDoneClicked")
        currentHabitIndex = sender.tag
        passwordWindowShowingForMarkHabitComplete = false
        passwordWindowShowingForMarkHabitSkip = false
        passwordWindowShowingForPastHabit = false
        if currentState == ._MORNING_HABIT_{
            if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipMorning{
                passwordWindowShowingForMarkHabitComplete = true
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                morningHabitAlreadyDoneClicked()
            }
        }else if currentState == ._EVENING_HABIT_{
            // Also enforce the "password to complete after cutoff" rule — previously only the
            // general skip-evening rule was checked here, so completing a habit past its cutoff
            // slipped through without a prompt.
            let afterCutoff = isCutOffTimeGoing() && SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff
            if shouldAskPassword() && (SettingsManagerObject.isPasswordRequireInSkipEvening || afterCutoff){
                passwordWindowShowingForMarkHabitComplete = true
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                eveningHabitAlreadyDoneClicked()
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            customHabitAlreadyDoneClicked()
        }
    }
    
    @objc func btnSkipClicked(sender: NSButton){
        addLog(text: "action bar:- btnSkipClicked")
        currentHabitIndex = sender.tag
        passwordWindowShowingForMarkHabitComplete = false
        passwordWindowShowingForMarkHabitSkip = false
        passwordWindowShowingForPastHabit = false
        if currentState == ._MORNING_HABIT_{
            if shouldAskPassword() && SettingsManagerObject.isPasswordRequireInSkipMorning{
                passwordWindowShowingForMarkHabitSkip = true
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                tryMorningRoutineSkip()
            }
        }else if currentState == ._EVENING_HABIT_{
            let afterCutoff = isCutOffTimeGoing() && SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff
            if shouldAskPassword() && (SettingsManagerObject.isPasswordRequireInSkipEvening || afterCutoff){
                passwordWindowShowingForMarkHabitSkip = true
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                tryEveningRoutineSkip()
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            customRoutineHabitSkipClicked()
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
