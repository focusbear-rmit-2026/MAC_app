//
//  pomodoroVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class pomodoroVc: NSViewController {
    
    @IBOutlet weak var lblSelectedStrictnessLevel: NSTextField!
    @IBOutlet weak var btnInfoStrictnessLevel: hoverInfoButton!
    @IBOutlet weak var btnPin: cursorButton!
    @IBOutlet weak var boxPin: NSBox!
    @IBOutlet weak var btnToggleBreaksSettingsInfo: hoverInfoButton!
    @IBOutlet weak var btnToggleBreaksSettings: underLineButton!
    @IBOutlet weak var lblTipPermissions: NSTextField!
    @IBOutlet weak var boxTipPermissions: NSBox!
    @IBOutlet weak var btnError: Button!
    @IBOutlet weak var boxError: NSBox!
    @IBOutlet weak var lblPercentageSign: NSTextField!
    @IBOutlet weak var lblTitleStrictnessLevel: NSTextField!
    @IBOutlet weak var btnStrictnessNormal: hoverInfoButton!
    @IBOutlet weak var btnStrictnessSuperStrict: hoverInfoButton!
    @IBOutlet weak var btnStrictnessStrict: hoverInfoButton!
    @IBOutlet weak var lblStrictnessNormal: NSTextField!
    @IBOutlet weak var lblStrictnessStrict: NSTextField!
    @IBOutlet weak var lblStrictnessSuperStrict: NSTextField!
    @IBOutlet weak var sliderStrictness: CustomSlider!
    @IBOutlet weak var btnEditRatio: NSButton!
    @IBOutlet weak var lblSelectedRatio: NSTextField!
    @IBOutlet weak var topSpaceLblTitle: NSLayoutConstraint!
    @IBOutlet weak var heightBtnChooseTask: NSLayoutConstraint!
    @IBOutlet weak var heightBtnLetsDoIt: NSLayoutConstraint!
    @IBOutlet weak var boxNewBadge: customNewBadgeBox!
    @IBOutlet weak var popUpBtnFocusAlignmentScore: NSPopUpButton!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var stackViewFocusAlignmentScore: NSStackView!
    @IBOutlet weak var lblWhatIsPomodoro: NSTextField!
    @IBOutlet weak var lblAdvancedMode: NSTextField!
    @IBOutlet weak var btnSwitchAdvancedMode: NSSwitch!
    @IBOutlet weak var lblTimerUnfocused: NSTextField!
//    @IBOutlet weak var checkBoxSkipMicrobreaks: NSButton!
    @IBOutlet weak var lblCompletedPomodoroCount: NSTextField!
    @IBOutlet weak var lblMinutesBreakDuration: NSTextField!
    @IBOutlet weak var lblMinutesWorkDuration: NSTextField!
    @IBOutlet weak var textFieldBreakDuration: NSTextField!
    @IBOutlet weak var textFieldWorkDuration: NSTextField!
    @IBOutlet weak var lblTitleBreakDuration: NSTextField!
    @IBOutlet weak var lblTitleWorkDuration: NSTextField!
    @IBOutlet weak var stackViewPomodoroModeTime: NSStackView!
    @IBOutlet weak var btnCheckBoxHardcodePomodoro: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var popUpBtnFocusType: NSPopUpButton!
    @IBOutlet weak var btnEditFocusMode: underLineButton!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet var textViewAchieve: NSTextView!
    @IBOutlet weak var lblHowManyPomodoro: NSTextField!
    @IBOutlet weak var popupBtnSelectPomodoroCount: NSPopUpButton!
    @IBOutlet weak var btnInfoPomodoro: cursorButton!
    
    var browserPermissionGiven = false
    
    var workRatio = 5
    var breakRatio = 1
    var isBreakDurationComesFromBreakRatio = false
    var isShowingMorningPomodoro = false
    var isShowingPomodoroManually = false
    var isShowingMorningHardcorePomodoro = false
    var questionSecondText = "Which block list do you want to use?"
    var chooseTheFocusModeText = "Choose the focus mode and duration - you won't be able to change the focus mode until the time is up (you still get to use any app/website during the 5 minutes break)"
    
    var workDurationEmptyErrorText = "Work Duration can not be empty."
    var workDurationZeroErrorText = "Work Duration can not be 0."
    var breakDurationEmptyErrorText = "Break Duration can not be empty."
    var breakDurationZeroErrorText = "Break Duration can not be 0."
    
    var timerText = "Time spend unfocused: <TIME>"
    
    let noItemSelectedIndex = -1
    let defaultIndex = 0
    var isSkipMicrobreaks = false
    
    var isFrictionLevelHigh = false
    var popoverInfo:NSPopover?// = NSPopover()
    
    var pomodoroTooltipVcObj:pomodoroTooltipVc?
    var alertExtendPostpone: NSAlert?
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc // only for cutOffTime in hardskip

    
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    var arrTourMessages: [[String : String]] = []
    var currentTourIndex = 0
    var isIntentionFromMorningPostpone = false
    var timerMoveWindowToCenter:Timer?
    var intentionToShowAgain = ""
    var titleBreaksOff = "Micro-breaks off"
    var titleBreaksOn = "Micro-breaks on"
    var pinButtonTrackingArea: NSTrackingArea?
    var titleNormalMode = "Chill Mode"
    var descriptionNormalMode = "Stop focusing anytime, no questions asked."
    var toolTipNormalMode = "Best for gentle focus days. No barriers to pausing or stopping a session."
    var titleStrictMode = "Wait for it…"
    var descriptionStrictMode = "15-second delay before you can stop"
    var toolTipStrictMode = "Adds a 15s countdown before you can pause/stop. Great for catching impulsive decisions."
    var titleSuperStrictMode = "Iron Focus"
    var descriptionSuperStrictMode = "Once you start, you can't stop"
    var toolTipSuperStrictMode = "Once you start, there’s no backing out. Best for deep, distraction-free sessions."
    var titleAfterPostpone = "What do you want to do instead of your habits?"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        arrTourMessages.removeAll()
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        lblStrictnessNormal.stringValue = "Normal"
        lblStrictnessStrict.stringValue = "Strict"
        lblStrictnessSuperStrict.stringValue = "Super strict"
        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        lblSelectedRatio.stringValue = "Based on a 3 to 1 work to break ratio."
        btnEditRatio.title = "Edit"
        lblFocusAlignmentScore.stringValue = "Show distracting site popup only when focus alignment score is less than"
        
        lblWhatIsPomodoro.stringValue = "What is Pomodoro?"
        lblAdvancedMode.stringValue = "Show advanced options"
//        lblFrictionLevel.stringValue = "low"
//        lblTitleFrictionLevel.stringValue = "Friction level:"

//        checkBoxSkipMicrobreaks.title = "Skip microbreaks during work blocks?"
        textFieldBreakDuration.formatter = IntegerFormatter()
        textFieldWorkDuration.formatter = IntegerFormatter()
        textFieldWorkDuration.delegate = self
        textFieldBreakDuration.delegate = self
        lblTitleWorkDuration.stringValue = "Focus Mode duration:"
        lblTitleBreakDuration.stringValue = "Break duration:"
        lblMinutesWorkDuration.stringValue = "minutes"
        lblMinutesBreakDuration.stringValue = "minutes"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            lblMinutesWorkDuration.stringValue = preferencesInfo.value(forKey: "minutesText") as? String ?? lblMinutesWorkDuration.stringValue
            lblTitleBreakDuration.stringValue = preferencesInfo.value(forKey: "breakDurationText") as? String ?? lblTitleBreakDuration.stringValue
            lblMinutesBreakDuration.stringValue = preferencesInfo.value(forKey: "minutesText") as? String ?? lblMinutesBreakDuration.stringValue
            
            workDurationEmptyErrorText = preferencesInfo.value(forKey: "workDurationEmptyErrorText") as? String ?? workDurationEmptyErrorText
            workDurationZeroErrorText = preferencesInfo.value(forKey: "workDurationZeroErrorText") as? String ?? workDurationZeroErrorText
            breakDurationEmptyErrorText = preferencesInfo.value(forKey: "breakDurationEmptyErrorText") as? String ?? breakDurationEmptyErrorText
            breakDurationZeroErrorText = preferencesInfo.value(forKey: "breakDurationZeroErrorText") as? String ?? breakDurationZeroErrorText
            
        }
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                lblTitleFrictionLevel.stringValue = startingFocusModeInfo.value(forKey: "titleFrictionLevel") as? String ?? lblTitleFrictionLevel.stringValue
//                frictionLevelLowText = startingFocusModeInfo.value(forKey: "frictionLevelLowText") as? String ?? frictionLevelLowText
//                frictionLevelHighText = startingFocusModeInfo.value(forKey: "frictionLevelHighText") as? String ?? frictionLevelHighText
//                lblStrictnessNormal.stringValue = startingFocusModeInfo.value(forKey: "strictnessNormalText") as? String ?? lblStrictnessNormal.stringValue
//                lblStrictnessStrict.stringValue = startingFocusModeInfo.value(forKey: "strictnessStrictText") as? String ?? lblStrictnessStrict.stringValue
//                lblStrictnessSuperStrict.stringValue = startingFocusModeInfo.value(forKey: "strictnessSuperStrictText") as? String ?? lblStrictnessSuperStrict.stringValue
                lblTitleStrictnessLevel.stringValue = startingFocusModeInfo.value(forKey: "titleStrictnessLevel") as? String ?? lblTitleStrictnessLevel.stringValue
            }
        }
        
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            lblFocusAlignmentScore.stringValue = focusPreferencesAdvancedInfo.value(forKey: "focusAlignmentScoreTitle") as? String ?? lblFocusAlignmentScore.stringValue
        }
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
        }
        btnError.title = "Fix it"
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            btnError.title = simplePomodoroVcInfo.value(forKey: "buttonFixItText") as? String ?? btnError.title
        }
        
        lblTitle.stringValue = "Pomodoro time!"
        //What do you want to do instead of your habits?
        var questionFirstText = "What do you want to achieve in this focus session?"
        
        btnEditFocusMode.title = "Edit block lists"
        btnLetsDoIt.title = "Let's do it"
        btnCheckBoxHardcodePomodoro.title = "Use hardcode pomodoro mode (lock in the focus mode for multiple pomodoros)"
        lblHowManyPomodoro.stringValue = "How many pomodoros you want to focus for:"

        var tourSelectTasks = "Select tasks"
        var descriptionSelectTasks = "Choose tasks to focus on from Focus Bear's inbuilt to do list"
        var tourIntention = "Freeform intention"
        var descriptionIntention = "If you don't want to bother creating tasks, you can write a quick intention for what you'll do during this focus session"
        
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            lblTitle.stringValue = pomodoroInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            titleAfterPostpone = pomodoroInfo.value(forKey: "titleAfterPostpone") as? String ?? titleAfterPostpone
            if let questionFirst = pomodoroInfo.value(forKey: "questionFirstText") as? String{
                questionFirstText = questionFirst
            }
            if let questionSecondText = pomodoroInfo.value(forKey: "titleSelectBlockList") as? String{
                self.questionSecondText = questionSecondText
            }
            if let buttonEditBlockListsText = pomodoroInfo.value(forKey: "buttonEditBlockListsText") as? String{
                btnEditFocusMode.title = buttonEditBlockListsText
            }
            if let buttonLetsDoItText = pomodoroInfo.value(forKey: "buttonLetsDoItText") as? String{
                btnLetsDoIt.title = buttonLetsDoItText
            }
            
            if let buttonHardcorePomodoroText = pomodoroInfo.value(forKey: "buttonHardcorePomodoroText") as? String{
                btnCheckBoxHardcodePomodoro.title = buttonHardcorePomodoroText
            }
            
            if let howManyPomodoroText = pomodoroInfo.value(forKey: "howManyPomodoroText") as? String{
                lblHowManyPomodoro.stringValue = howManyPomodoroText
            }
            
            if let chooseTheFocusModeText = pomodoroInfo.value(forKey: "chooseTheFocusModeText") as? String{
                self.chooseTheFocusModeText = chooseTheFocusModeText
            }
//            checkBoxSkipMicrobreaks.title = pomodoroInfo.value(forKey: "buttonSkipMicrobreaksText") as? String ?? checkBoxSkipMicrobreaks.title
            timerText = pomodoroInfo.value(forKey: "timerText") as? String ?? timerText
            lblWhatIsPomodoro.stringValue = pomodoroInfo.value(forKey: "whatIsPomodoroText") as? String ?? lblWhatIsPomodoro.stringValue
            lblAdvancedMode.stringValue = pomodoroInfo.value(forKey: "buttonAdvancedOptionsText") as? String ?? lblAdvancedMode.stringValue
            
            tourSelectTasks = pomodoroInfo.value(forKey: "tourSelectTasks") as? String ?? tourSelectTasks
            descriptionSelectTasks = pomodoroInfo.value(forKey: "descriptionSelectTasks") as? String ?? descriptionSelectTasks
            tourIntention = pomodoroInfo.value(forKey: "tourIntention") as? String ?? tourIntention
            descriptionIntention = pomodoroInfo.value(forKey: "descriptionIntention") as? String ?? descriptionIntention
            btnEditRatio.title = pomodoroInfo.value(forKey: "buttonEditRatioText") as? String ?? btnEditRatio.title
            titleBreaksOff = pomodoroInfo.value(forKey: "titleBreaksOff") as? String ?? titleBreaksOff
            titleBreaksOn = pomodoroInfo.value(forKey: "titleBreaksOn") as? String ?? titleBreaksOn
            lblTitleWorkDuration.stringValue = pomodoroInfo.value(forKey: "pomodoroModeDurationText") as? String ?? lblTitleWorkDuration.stringValue
        }
        
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            titleNormalMode = simplePomodoroVcInfo.value(forKey: "titleNormalMode") as? String ?? titleNormalMode
            descriptionNormalMode = simplePomodoroVcInfo.value(forKey: "descriptionNormalMode") as? String ?? descriptionNormalMode
            toolTipNormalMode = simplePomodoroVcInfo.value(forKey: "toolTipNormalMode") as? String ?? toolTipNormalMode
            titleStrictMode = simplePomodoroVcInfo.value(forKey: "titleStrictMode") as? String ?? titleStrictMode
            descriptionStrictMode = simplePomodoroVcInfo.value(forKey: "descriptionStrictMode") as? String ?? descriptionStrictMode
            toolTipStrictMode = simplePomodoroVcInfo.value(forKey: "toolTipStrictMode") as? String ?? toolTipStrictMode
            titleSuperStrictMode = simplePomodoroVcInfo.value(forKey: "titleSuperStrictMode") as? String ?? titleSuperStrictMode
            descriptionSuperStrictMode = simplePomodoroVcInfo.value(forKey: "descriptionSuperStrictMode") as? String ?? descriptionSuperStrictMode
            toolTipSuperStrictMode = simplePomodoroVcInfo.value(forKey: "toolTipSuperStrictMode") as? String ?? toolTipSuperStrictMode
        }
        
        lblStrictnessNormal.stringValue = "🟢 " + titleNormalMode
        lblStrictnessStrict.stringValue = "🟡 " + titleStrictMode
        lblStrictnessSuperStrict.stringValue = "🔴 " + titleSuperStrictMode
        
        arrTourMessages.append(["title": tourSelectTasks, "description": descriptionSelectTasks])
        arrTourMessages.append(["title": tourIntention, "description": descriptionIntention])

        lblQuestionFirst.stringValue = questionFirstText
        popUpBtnFocusType.removeAllItems()
        
        lblQuestionSecond.stringValue = questionSecondText
        
        popupBtnSelectPomodoroCount.removeAllItems()
        for i in 2...20{
            popupBtnSelectPomodoroCount.addItem(withTitle: "\(i)")
        }
        lblCompletedPomodoroCount.isHidden = true
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAdvancedPomodoroEnabled) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsIsAdvancedPomodoroEnabled)
        }
        popUpBtnFocusAlignmentScore.removeAllItems()
        popUpBtnFocusAlignmentScore.addItems(withTitles: arrFocusAlignmentScore)
        viewDidResize()
        

        
        for i in 0..<arrTourMessages.count{
            if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }

        pinButtonTrackingArea = NSTrackingArea.init(rect: btnPin.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnPin.addTrackingArea(pinButtonTrackingArea!)
        
        
        btnToggleBreaksSettingsInfo.isAutoClickEnabled = false
        btnStrictnessNormal.isAutoClickEnabled = false
        btnStrictnessSuperStrict.isAutoClickEnabled = false
        btnStrictnessStrict.isAutoClickEnabled = false
        btnInfoStrictnessLevel.isAutoClickEnabled = false
    }

    override func viewDidAppear() {
        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
            boxPin.isHidden =  false
            btnPin.image = #imageLiteral(resourceName: "unPin")
//            self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
        }else{
            boxPin.isHidden = true
//            self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow))) // recheck all these window level code
        }
        boxPin.isHidden = true
        
        boxError.isHidden = true
        boxTipPermissions.isHidden = true
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            boxError.isHidden = false
            browserPermissionGiven = false
            boxTipPermissions.isHidden = false
        }else{
            boxError.isHidden = true
            browserPermissionGiven = false
            boxTipPermissions.isHidden = true
            DispatchQueue.global().async {
                if let arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
                    for i in 0..<arrBrowsersInfo.count{
                        let info = arrBrowsersInfo[i]
                        let isEnabled = info["isEnabled"] as? Bool ?? false
                        if isEnabled{
                            self.browserPermissionGiven = true
                            break;
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if !self.browserPermissionGiven{
                        self.boxError.isHidden = false
                        self.boxTipPermissions.isHidden = false
                    }
                }
                
            }
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            lblTipPermissions.stringValue = "Want to block distractions during this focus session? Grant Focus Bear permissions to block."
            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                lblTipPermissions.stringValue = simplePomodoroVcInfo.value(forKey: "tipPermissionsFirst") as? String ?? lblTipPermissions.stringValue
            }
        }else if !browserPermissionGiven{
            lblTipPermissions.stringValue = "Distraction blocking inactive: Focus Bear doesn’t have permissions for any of your browsers."
            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                lblTipPermissions.stringValue = simplePomodoroVcInfo.value(forKey: "tipPermissionsSecond") as? String ?? lblTipPermissions.stringValue
            }
        }
        
        if popUpBtnFocusType.isEnabled{
            if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                if currentFocusModeStrictness == ._SUPER_STRICT_{
                    for index in 0..<customBlockingScheduleManagerObj.arrBlockingSchedule.count{
                        if customBlockingScheduleManagerObj.arrBlockingSchedule[index].state == .on{
                            let id = customBlockingScheduleManagerObj.arrBlockingSchedule[index].focusModeID
                            for i in 0..<arrFocusTypeForPomodoro.count{
                                let focusMode = arrFocusTypeForPomodoro[i]
                                if let idFocusTypeForPomodoro = focusMode["id"] as? String{
                                    if idFocusTypeForPomodoro == id{
                                        popUpBtnFocusType.selectItem(at: i)
                                        popUpBtnFocusType.isEnabled = false
                                        popoverTooltip?.close()
                                        break;
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == pinButtonTrackingArea{
            var pinWindowText = "Click to unpin the window (disable stay-on-top)"
            if self.view.window?.level == NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow))){
                pinWindowText = "Click to unpin the window (disable stay-on-top)"
                if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                    pinWindowText = pomodoroInfo.value(forKey: "unpinWindowText") as? String ?? pinWindowText
                }
                
            }else{
                pinWindowText = "Click to pin the window (keep on top)"
                if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                    pinWindowText = pomodoroInfo.value(forKey: "pinWindowText") as? String ?? pinWindowText
                }
            }
            showTooltip(sender: btnPin, msg: pinWindowText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == pinButtonTrackingArea{
            if popoverInfo != nil{
                if popoverInfo!.isShown{
                    popoverInfo?.close()
                }
            }
        }
    }
    
    func updateBreakDuration(){
        let workDuration = textFieldWorkDuration.integerValue
        
        var breakDuration =  Int((Double(workDuration) / Double(workRatio)) * Double(breakRatio))
        if breakDuration < 1{
            breakDuration = 1
        }
        textFieldBreakDuration.stringValue = "\(breakDuration)"
        isBreakDurationComesFromBreakRatio = true
        print("isBreakDurationComesFromBreakRatio true")
    }
    
    func selectFocusModeWithId(id:String, duration:Int){
        var focusFoundWithId = false
        for i in 0..<arrFocusTypeForPomodoro.count{
            let focusMode = arrFocusTypeForPomodoro[i]
            if let idFocusTypeForPomodoro = focusMode["id"] as? String{
                if idFocusTypeForPomodoro == id{
                    popUpBtnFocusType.selectItem(at: i)
                    textFieldWorkDuration.integerValue = duration/60
                    updateBreakDuration()
                    focusFoundWithId = true
                    break;
                }
            }
        }
        if !focusFoundWithId{
            showAlert(msg: "Focus mode not found.")
        }
    }
    
    func updateWorkBreakRatio(){
        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro) as? Int{
            workRatio = ratio
        }
        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro) as? Int{
            breakRatio = ratio
        }
        
        var workRatioText = "Break duration is based on <WORKRATIO> to <BREAKRATIO> minutes work to break ratio."
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            workRatioText = pomodoroInfo.value(forKey: "workRatioText") as? String ?? workRatioText
        }
        workRatioText = workRatioText.replacingOccurrences(of: "<WORKRATIO>", with: "\(workRatio)")
        workRatioText = workRatioText.replacingOccurrences(of: "<BREAKRATIO>", with: "\(breakRatio)")
        
        lblSelectedRatio.stringValue = workRatioText
    }
    
    override func viewWillAppear() {
        if let index = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeStrictness) as? Int{
            sliderStrictness.integerValue = index
        }else{
            if SettingsManagerObject.isCuddlyModeEnabled{
                sliderStrictness.integerValue = 1
            }else{
                sliderStrictness.integerValue = 3
            }
        }
        showSelectedStrictnessLevel()
        
        updateWorkBreakRatio()
        getTaskPlayerVcObject().loadView()
        getTaskPlayerVcObject().loadRequest()
        reFillFocusTypeList()
//        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
//            if startingFocusWindowControllerObj?.contentViewController == startingFocusModeVcObj{
//                startingFocusWindowControllerObj?.close()
//            }
//        }
        isFrictionLevelHigh = false
        
        
        if isShowingMorningHardcorePomodoro{
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                    isFrictionLevelHigh = true
                }
            }
            lblTimerUnfocused.isHidden = true
            if let count = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedCount) as? Int{
                popupBtnSelectPomodoroCount.selectItem(withTitle: "\(count)")
            }else{
                popupBtnSelectPomodoroCount.selectItem(withTitle: "2")
            }
            if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                popUpBtnFocusType.selectItem(withTitle: name)
            }
            
            if popUpBtnFocusType.indexOfSelectedItem == noItemSelectedIndex{//noItemSelectedIndex shows there is no item seleted so select at 0 index
                popUpBtnFocusType.selectItem(at: defaultIndex)
            }
            
            if let val = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroSkipMicroBreaks) as? Bool{
                if val{
                    btnToggleBreaksSettings.title = titleBreaksOff
                    isSkipMicrobreaks = true
                }else{
                    btnToggleBreaksSettings.title = titleBreaksOn
                    isSkipMicrobreaks = false
                }
            }else{
                btnToggleBreaksSettings.title = titleBreaksOn
                isSkipMicrobreaks = false
            }

            btnLetsDoIt.isEnabled = true
            btnCheckBoxHardcodePomodoro.state = .on
            btnCheckBoxHardcodePomodoro.isEnabled = false
            popUpBtnFocusType.isEnabled = false
            btnEditFocusMode.isEnabled = false
            popupBtnSelectPomodoroCount.isEnabled = false
            lblQuestionSecond.stringValue = chooseTheFocusModeText
            stackViewPomodoroModeTime.isHidden = false
            textFieldWorkDuration.isEnabled = false
            textFieldBreakDuration.isEnabled = false
            btnToggleBreaksSettings.isEnabled = false
            popUpBtnFocusAlignmentScore.isEnabled = false
            sliderStrictness.isEnabled = false
            if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
                textFieldWorkDuration.stringValue = "\(duration)"
            }
            
            updateBreakDuration()
        }else if isHardCorePomodoroModeOn{
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                    isFrictionLevelHigh = true
                }
            }
            lblTimerUnfocused.isHidden = true
            btnLetsDoIt.isEnabled = true
            btnCheckBoxHardcodePomodoro.isEnabled = false
            popUpBtnFocusType.selectItem(withTitle: hardcodePmodoroFocusModeName)
            popUpBtnFocusType.isEnabled = false
            btnEditFocusMode.isEnabled = false
            popupBtnSelectPomodoroCount.isEnabled = false
            lblQuestionSecond.stringValue = chooseTheFocusModeText
            stackViewPomodoroModeTime.isHidden = false
            btnCheckBoxHardcodePomodoro.state = .on
            textFieldWorkDuration.isEnabled = false
            textFieldBreakDuration.isEnabled = false
            lblCompletedPomodoroCount.isHidden = false
            btnToggleBreaksSettings.isEnabled = false
            popUpBtnFocusAlignmentScore.isEnabled = false
            sliderStrictness.isEnabled = false
            let remainingPomodoroCount = totalPomodoroCountInHardCorePomodoro - completedPomodoroCountInHardcorePomodoro
            var completedPomodoroCountText = "You have completed <COMPLETED_POMODORO> of <TOTAL_POMODORO> pomodoros. <REMAINING_POMODORO> more to go."
            
            if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                if let title = pomodoroInfo.value(forKey: "completedPomodoroCountText") as? String{
                    completedPomodoroCountText = title
                }
            }
            
            completedPomodoroCountText = completedPomodoroCountText.replacingOccurrences(of: "<COMPLETED_POMODORO>", with: "\(completedPomodoroCountInHardcorePomodoro)")
            completedPomodoroCountText = completedPomodoroCountText.replacingOccurrences(of: "<TOTAL_POMODORO>", with: "\(totalPomodoroCountInHardCorePomodoro)")
            completedPomodoroCountText = completedPomodoroCountText.replacingOccurrences(of: "<REMAINING_POMODORO>", with: "\(remainingPomodoroCount)")
            lblCompletedPomodoroCount.stringValue = completedPomodoroCountText//"You have completed \(completedPomodoroCountInHardcorePomodoro) of \(totalPomodoroCountInHardCorePomodoro) pomodoros. \(remainingPomodoroCount) more to go."//
            
        }else{
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroSkipMicroBreaks) as? Bool{
                if state{
                    btnToggleBreaksSettings.title = titleBreaksOff
                    isSkipMicrobreaks = true
                }else{
                    btnToggleBreaksSettings.title = titleBreaksOn
                    isSkipMicrobreaks = false
                }
            }else{
                btnToggleBreaksSettings.title = titleBreaksOff
                isSkipMicrobreaks = true
            }
            lblTimerUnfocused.isHidden = false
            startTimer()
            lblCompletedPomodoroCount.isHidden = true
            textFieldWorkDuration.isEnabled = true
            textFieldBreakDuration.isEnabled = true
            sliderStrictness.isEnabled = true
            btnCheckBoxHardcodePomodoro.state = .off
            btnCheckBoxHardcodePomodoro.isEnabled = true
            popUpBtnFocusType.isEnabled = true
            btnEditFocusMode.isEnabled = true
            btnToggleBreaksSettings.isEnabled = true
            popUpBtnFocusAlignmentScore.isEnabled = true
            btnLetsDoIt.isEnabled = true
            popupBtnSelectPomodoroCount.isEnabled = true
            if btnCheckBoxHardcodePomodoro.state == .on{
                lblQuestionSecond.stringValue = chooseTheFocusModeText
                stackViewPomodoroModeTime.isHidden = false
            }else{
                lblQuestionSecond.stringValue = questionSecondText
                stackViewPomodoroModeTime.isHidden = true
                
            }
            if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
                textFieldWorkDuration.stringValue = "\(duration)"
            }
            
            updateBreakDuration()
        }

        isFocusModeStartedAutomatically = false
        if isShowingMorningHardcorePomodoro{
            isHardCorePomodoroModeOn = true
            self.view.window?.styleMask.remove(.closable)
            currentPomodoroWorkDuration = textFieldWorkDuration.integerValue
            currentPomodoroBreakDuration = textFieldBreakDuration.integerValue
            hardcodePmodoroFocusModeName = popUpBtnFocusType.titleOfSelectedItem ?? ""
            let totalPopmodoroCount = Int(popupBtnSelectPomodoroCount.title) ?? 2
            let minutes = currentPomodoroWorkDuration
            totalPomodoroCountInHardCorePomodoro = totalPopmodoroCount
            completedPomodoroCountInHardcorePomodoro = 0
            
            let totoalMinutes = (totalPopmodoroCount * minutes) //* 60//(textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
            totalMinutesRemainingForHardcodePomodoro = totoalMinutes
            allApiObject.capturePosthog(event: "start-super-focus-session-automatically", metadata: [:])
            isFocusModeStartedAutomatically = true
            focusModeSelected()
            pomodoroModeStarted()
        }else{
            if isHardCorePomodoroModeOn{
                focusModeSelected()
                isFocusModeStartedAutomatically = true
                pomodoroModeStarted()
                self.view.window?.styleMask.remove(.closable)
            }else{
                focusModeSelected()
                self.view.window?.styleMask.insert(.closable)
            }
        }
        
        
        
//        addTaskVcObj = getAddTaskVcObject()
//        if !addTaskVcObj.isViewLoaded{
//            addTaskVcObj.loadView()
//        }
//        addTaskVcObj.reloadData(isAddingTask: true)
        
        if let boolValue = UserDefaults.standard.object(forKey: kUserdefaultsIsAdvancedPomodoroEnabled) as? Bool{
            btnCheckBoxHardcodePomodoro.isHidden = !boolValue
            stackViewFocusAlignmentScore.isHidden = true
            if boolValue{
                if SettingsManagerObject.isCuddlyModeEnabled && SettingsManagerObject.isAiCheckUrlEnabled && sliderStrictness.integerValue != 3{
                    stackViewFocusAlignmentScore.isHidden = false
                }
            }
            
            if boolValue{
                btnSwitchAdvancedMode.state = .on
            }else{
                btnSwitchAdvancedMode.state = .off
            }
        }
        
        viewDidResize()
        if !nextFocusSessionIntention.isEmpty{
            textViewAchieve.string = nextFocusSessionIntention
        }
    }
    
    func showSelectedStrictnessLevel(){
        if sliderStrictness.integerValue == 1{
            lblSelectedStrictnessLevel.stringValue = titleNormalMode + " (\(descriptionNormalMode))"
        }else if sliderStrictness.integerValue == 2{
            lblSelectedStrictnessLevel.stringValue = titleStrictMode + " (\(descriptionStrictMode))"
        }else if sliderStrictness.integerValue == 3{
            lblSelectedStrictnessLevel.stringValue = titleSuperStrictMode + " (\(descriptionSuperStrictMode))"
        }
    }
    
    //Re-center the pomodoro popup if user takes no action #1053
//    func setTimerMoveWindowToCenter(){
//        removeTimerMoveWindowToCenter()
//        self.timerMoveWindowToCenter = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.moveWindowToCenter), userInfo: nil, repeats: true)
//    }
    
//    func removeTimerMoveWindowToCenter(){
//        if self.timerMoveWindowToCenter != nil{
//            self.timerMoveWindowToCenter?.invalidate()
//            self.timerMoveWindowToCenter = nil
//        }
//    }
    
//    @objc func moveWindowToCenter() {
//        if let window = self.view.window{
//            if window.isVisible{
//                if let screen = NSScreen.screens.first {
//                    let screenFrame = screen.frame
//                    let windowFrame = window.frame
//                    let newOriginX = screenFrame.midX - (windowFrame.width / 2)
//                    let newOriginY = screenFrame.midY - (windowFrame.height / 2)
//                    window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
//                }
//            }
//        }
//        removeTimerMoveWindowToCenter()
//    }
    //-----------------------------------------------//
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here 
        btnLetsDoIt.title = btnLetsDoIt.title
    }
    
    @objc func viewDidResize(){
        print("viewDidResize")
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        if screenFrame.height < 900{
            var fontSizeNinteen:CGFloat = 19
            var fontSizeTwelve:CGFloat = 12
            var fontSizeEleven:CGFloat = 11
            var fontSizeSixteen:CGFloat = 16
            
            
            if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
                fontSizeNinteen = 14
                fontSizeTwelve = 9
                fontSizeEleven = 9
                fontSizeSixteen = 13
                
                heightBtnLetsDoIt.constant = 30
                heightBtnChooseTask.constant = 22
                topSpaceLblTitle.constant = 10
            }else{
                heightBtnLetsDoIt.constant = 34
                heightBtnChooseTask.constant = 26
                topSpaceLblTitle.constant = 20
            }
            lblTitle.font = getRegularFont(size: fontSizeNinteen)
            btnCheckBoxHardcodePomodoro.font = getRegularFont(size: fontSizeTwelve)
            lblQuestionFirst.font = getRegularFont(size: fontSizeTwelve)
            lblQuestionSecond.font =  getRegularFont(size: fontSizeTwelve)
            popUpBtnFocusType.font =  getRegularFont(size: fontSizeEleven)
            btnEditFocusMode.font =  getRegularFont(size: fontSizeEleven)
            lblHowManyPomodoro.font =  getRegularFont(size: fontSizeTwelve)
            popupBtnSelectPomodoroCount.font =  getRegularFont(size: fontSizeEleven)
            lblTitleWorkDuration.font =  getRegularFont(size: fontSizeTwelve)
            lblTitleBreakDuration.font =  getRegularFont(size: fontSizeTwelve)
            lblMinutesWorkDuration.font =  getRegularFont(size: fontSizeTwelve)
            lblMinutesBreakDuration.font =  getRegularFont(size: fontSizeTwelve)
            textFieldWorkDuration.font =  getRegularFont(size: fontSizeEleven)
            textFieldBreakDuration.font =  getRegularFont(size: fontSizeEleven)
            btnToggleBreaksSettings.font =  getRegularFont(size: fontSizeTwelve)
            lblFocusAlignmentScore.font =  getRegularFont(size: fontSizeTwelve)
            popUpBtnFocusAlignmentScore.font =  getRegularFont(size: fontSizeEleven)
            lblTimerUnfocused.font =  getRegularFont(size: fontSizeTwelve)
            btnLetsDoIt.font =  getRegularFont(size: fontSizeSixteen)
            lblCompletedPomodoroCount.font =  getRegularFont(size: fontSizeTwelve)
            lblAdvancedMode.font =  getRegularFont(size: fontSizeTwelve)
            lblTitleStrictnessLevel.font =  getRegularFont(size: fontSizeTwelve)
            lblStrictnessNormal.font =  getRegularFont(size: fontSizeTwelve)
            lblStrictnessStrict.font =  getRegularFont(size: fontSizeTwelve)
            lblStrictnessSuperStrict.font =  getRegularFont(size: fontSizeTwelve)
        }else{
            lblTitle.font =  getRegularFont(size: 25)
            btnCheckBoxHardcodePomodoro.font =  getRegularFont(size: 14)
            lblQuestionFirst.font =  getRegularFont(size: 14)
            lblQuestionSecond.font =  getRegularFont(size: 14)
            popUpBtnFocusType.font =  getRegularFont(size: 13)
            btnEditFocusMode.font =  getRegularFont(size: 13)
            lblHowManyPomodoro.font =  getRegularFont(size: 15)
            popupBtnSelectPomodoroCount.font =  getRegularFont(size: 13)
            lblTitleWorkDuration.font =  getRegularFont(size: 14)
            lblTitleBreakDuration.font =  getRegularFont(size: 14)
            lblMinutesWorkDuration.font =  getRegularFont(size: 14)
            lblMinutesBreakDuration.font =  getRegularFont(size: 14)
            textFieldWorkDuration.font =  getRegularFont(size: 13)
            textFieldBreakDuration.font =  getRegularFont(size: 13)
            btnToggleBreaksSettings.font =  getRegularFont(size: 14)
            lblFocusAlignmentScore.font =  getRegularFont(size: 14)
            popUpBtnFocusAlignmentScore.font =  getRegularFont(size: 13)
            lblTimerUnfocused.font =  getRegularFont(size: 14)
            btnLetsDoIt.font =  getRegularFont(size: 20)
            lblCompletedPomodoroCount.font =  getRegularFont(size: 14)
            lblAdvancedMode.font =  getRegularFont(size: 13)
            heightBtnLetsDoIt.constant = 40
            heightBtnChooseTask.constant = 30
            topSpaceLblTitle.constant = 35
            lblTitleStrictnessLevel.font =  getRegularFont(size: 14)
            lblStrictnessNormal.font =  getRegularFont(size: 14)
            lblStrictnessStrict.font =  getRegularFont(size: 14)
            lblStrictnessSuperStrict.font =  getRegularFont(size: 14)
        }
    }

    
    func reFillFocusTypeList(){
        arrFocusTypeForPomodoro.removeAll()
        for i in 0..<arrFocusType.count{
            if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true){
                arrFocusTypeForPomodoro.append(arrFocusType[i])
            }
        }
        
        var index = popUpBtnFocusType.indexOfSelectedItem
        if index == noItemSelectedIndex{
            index = defaultIndex
        }
        popUpBtnFocusType.removeAllItems()
        for i in 0..<arrFocusTypeForPomodoro.count{
            if let name = arrFocusTypeForPomodoro[i]["name"] as? String{
                popUpBtnFocusType.addItem(withTitle: name)
            }
        }
        if arrFocusTypeForPomodoro.count <= index{
            index = defaultIndex
        }
        popUpBtnFocusType.selectItem(at: index)
        
        if let focusAlignmentScore = arrFocusTypeForPomodoro[index]["focusAlignmentScoreThreshold"] as? Int{
            popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(focusAlignmentScore)")
        }else{
            popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(defaultFocusAlignmentScoreToShowDistractingPopUp)")
        }

    }
    
    @IBAction func popUpBtnFocusTypeClicked(_ sender: Any) {
        focusModeSelected()
    }
    
    func focusModeSelected(){
        let index = popUpBtnFocusType.indexOfSelectedItem
        if let focusAlignmentScore = arrFocusTypeForPomodoro[index]["focusAlignmentScoreThreshold"] as? Int{
            popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(focusAlignmentScore)")
        }else{
            popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(defaultFocusAlignmentScoreToShowDistractingPopUp)")
        }
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                if let isDefault = arrFocusTypeForPomodoro[index]["isDefault"] as? Bool{
                    if  isDefault{
                        var warningDefaultFocusMode = "Heads up: this will not use AI blocking. Focus Bear will only block the sites in your super distracting sites list"
                        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                                warningDefaultFocusMode = startingFocusModeInfo.value(forKey: "warningDefaultFocusMode") as? String ?? warningDefaultFocusMode
                            }
                        }
                        if self.view.window != nil{
                            showTooltip(sender: self.popUpBtnFocusType, msg: warningDefaultFocusMode, preferredEdge: .minX, maxWidthVal: 250)
                        }
                    }
                }
            }
        }
        
        if isIntentionFromMorningPostpone{// only show intention from postpone habit box // 17/5/24
            return;
        }
        let lastIntentionUsed = arrFocusTypeForPomodoro[index]["lastIntentionUsed"] as? String ?? ""

        textViewAchieve.string = ""
        textViewAchieve.string = lastIntentionUsed
    }
    
    @IBAction func btnEditFocusModeClicked(_ sender: Any) {
        addLog(text: "[user-action] btnEditFocusModeClicked")
        addLog(text: "Showing preferences from edit focus mode")
        leftMenuVcObj?.showFocusModeSettingsView()
        if let focusModeId = arrFocusTypeForPomodoro[popUpBtnFocusType.indexOfSelectedItem]["id"] as? String{
            getFocusPreferencesVcObject().selectFocusModeWithId(id: focusModeId)
        }
            
    }
    
    func showAlert(msg:String){
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler:nil)
    }
    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "[user-action] btnLetsDoItClicked")//
        if textFieldWorkDuration.isEnabled{
            if textFieldWorkDuration.stringValue.isEmpty{
                showAlert(msg: workDurationEmptyErrorText)
                return;
            }
            if textFieldWorkDuration.integerValue < 1{
                showAlert(msg: workDurationZeroErrorText)
                return;
            }
        }
        if textFieldBreakDuration.isEnabled{
            if textFieldBreakDuration.stringValue.isEmpty{
                showAlert(msg: breakDurationEmptyErrorText)
                return;
            }
            if textFieldBreakDuration.integerValue < 1{
                showAlert(msg: breakDurationZeroErrorText)
                return;
            }
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
            let alertWarning = NSAlert()
            alertWarning.setSharingType()
            alertWarning.messageText = "Do you want to block distractions?"
            alertWarning.informativeText = "You can block distracting websites and distracting apps. You will need to allow permissions to block distracting websites."
            var buttonBlockText = "Yeah - block them!"
            var buttonNoText = "No thanks"
            
            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
                alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningSetDistractionsInfo") as? String ?? alertWarning.informativeText
                buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
                buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
            }
            
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if modalResponse == .alertFirstButtonReturn{
                    showDistractionTypesWindow(showingFromPomodoro: true)
                    self.intentionToShowAgain = self.textViewAchieve.string
                    self.view.window?.close()
                }else{
                    self.btnLetsDoItClicked(self)
                }
            })
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser)
            return;
        }else if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            let alertWarning = NSAlert()
            alertWarning.setSharingType()
            alertWarning.messageText = "Do you want to block distractions?"
            alertWarning.informativeText = "You will need to allow permissions to block distracting websites."
            var buttonBlockText = "Yeah - block them!"
            var buttonNoText = "No thanks"
            
            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
                alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsInfo") as? String ?? alertWarning.informativeText
                buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
                buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
            }
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if modalResponse == .alertFirstButtonReturn{
                    showExplainingPermissionsWindow(showingFromPomodoro: true)
                    self.intentionToShowAgain = self.textViewAchieve.string
                    self.view.window?.close()
                }else{
                    self.btnLetsDoItClicked(self)
                }
            })
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            return;
        }
        
        if isHardCorePomodoroModeOn{
            whatToAchieveInFocusBlock = textViewAchieve.string
            appdelegate!.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
            if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                let minute = textFieldWorkDuration.integerValue
                showTaskPlayerWindow(totalDuration: minute, intention: textViewAchieve.string, automatically:true)
            }else{
                let minute = textFieldWorkDuration.integerValue
                if !getTaskPlayerVcObject().isViewLoaded{
                    getTaskPlayerVcObject().loadView()
                }
                taskPlayerVcObj?.reloadData(totalDuration: minute, intention: textViewAchieve.string)
                shouldReloadTaskPlayer = false
            }
            
            if let focusModeId = arrFocusTypeForPomodoro[popUpBtnFocusType.indexOfSelectedItem]["id"] as? String{
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["id"] as? String ?? "" == focusModeId{
                        updateFocusModeTask(taskString: arrFocusType[i]["lastTaskUsed"] as? String ?? "")
                        if !textViewAchieve.string.isEmpty{
                            arrFocusType[i]["lastIntentionUsed"] = textViewAchieve.string
                        }else{
                            arrFocusType[i]["lastIntentionUsed"] = ""
                        }
                        
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        updateAllFocusModes()
                        break;
                    }
                }
            }
            self.view.window?.close()
            allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
            return;
        }
        
        if textFieldWorkDuration.isEnabled{
            currentPomodoroWorkDuration = textFieldWorkDuration.integerValue
        }
        if textFieldBreakDuration.isEnabled{
            currentPomodoroBreakDuration = textFieldBreakDuration.integerValue
        }
        
        if isHardCorePomodoroModeOn{
            
        }else if btnCheckBoxHardcodePomodoro.state == .on{
            isHardCorePomodoroModeOn = true
            hardcodePmodoroFocusModeName = popUpBtnFocusType.titleOfSelectedItem ?? ""
            let totalPopmodoroCount = Int(popupBtnSelectPomodoroCount.title) ?? 2
            let minutes = textFieldWorkDuration.integerValue
            totalPomodoroCountInHardCorePomodoro = totalPopmodoroCount
            completedPomodoroCountInHardcorePomodoro = 0
            
            let totoalMinutes = (totalPopmodoroCount * minutes) //* 60//(textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
            totalMinutesRemainingForHardcodePomodoro = totoalMinutes
        }
        
        
        let totalMinutes = textFieldWorkDuration.integerValue
        
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
                        
                        alertExtendPostpone!.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            if modalResponse == .alertFirstButtonReturn{
                                if currentState == ._POSTPON_MORNING_HABIT_{
                                    
                                    
                                    if SettingsManagerObject.isEasySkipEnabled{
                                        getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        self.checkStateAndStartPomodoroMode()
                                    }else{
                                        if SettingsManagerObject.isPasswordRequireInSkipMorning && shouldAskPassword(){
                                            self.presentAsSheet(self.enterPasswordVcObj!)
                                            self.enterPasswordVcObj?.parentVc = self
                                            self.enterPasswordVcObj?.isShowingForRelaxFocusMode = false
                                            return;
                                        }else{
                                            getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                            self.checkStateAndStartPomodoroMode()
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
                                        self.enterPasswordVcObj?.isShowingForRelaxFocusMode = false
                                        return;
                                    }else{
                                        if currentState == ._POSTPON_EVENING_HABIT_{
                                            getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
                                            getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                                        }
                                        self.checkStateAndStartPomodoroMode()
                                    }
                                }
                            }else if modalResponse == .alertSecondButtonReturn{
                                self.checkStateAndStartPomodoroMode()
                            }
                        })
                        return;
                    }
                }
            }
        }
        checkStateAndStartPomodoroMode()
    }
   
    func checkStateAndStartPomodoroMode(){
        nextFocusSessionIntention = ""
        let isRelaxFocus = arrFocusTypeForPomodoro[popUpBtnFocusType.indexOfSelectedItem]["isRelaxFocus"] as? Bool ?? false
        if isRelaxFocus && shouldAskPassword() && SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
            if self.view.window != nil{
                self.presentAsSheet(self.enterPasswordVcObj!)
                self.enterPasswordVcObj?.parentVc = self
                self.enterPasswordVcObj?.isShowingForRelaxFocusMode = true
            }else{
                pomodoroModeStarted()
                if currentState != ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
                    
                    self.view.window?.close()//  will not work if view has changed (task player is viisble now). because if main view is changes then window is nil.no need to change anything
                }else{
                    leftMenuVcObj?.showBreaksView()
                }
                allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
            }
        }else{
            pomodoroModeStarted()
            if currentState != ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
                
                self.view.window?.close()//  will not work if view has changed (task player is viisble now). because if main view is changes then window is nil.no need to change anything
            }else{
                leftMenuVcObj?.showBreaksView()
            }
            allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
        }
    }
    
    func pomodoroModeStarted(){
        addLog(text: "pomodoro mode Started")
        if arrFocusTypeForPomodoro.count == 0{
            return
        }
        if sliderStrictness.integerValue == 1{
            addLog(text: "focus mode is normal mode")
            currentFocusModeStrictness = ._NORMAL_
        }else if sliderStrictness.integerValue == 2{
            addLog(text: "focus mode is strict mode")
            currentFocusModeStrictness = ._STRICT_
        }else if sliderStrictness.integerValue == 3{
            addLog(text: "focus mode is super strict mode")
            currentFocusModeStrictness = ._SUPER_STRICT_
        }
        
        UserDefaults.standard.set(sliderStrictness.integerValue, forKey: kUserdefaultsLastFocusModeStrictness)

        //App should remember the last focus session + break duration. If you change it to 40 minutes, it should remember that for next time.
        // 29/7/25 v 1.26.395
        let count = textFieldWorkDuration.integerValue
        if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
            if count != oldCount{
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes)
                SettingsManagerObject.putUserLocalDeviceSettings()
            }
        }

//        if getEndFocusModeWindowControllerObj().window!.isVisible{
//            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
//            addEntryInStatsCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
//            getEndFocusModeWindowControllerObj().window?.close()
//        }
        let minute = textFieldWorkDuration.integerValue
        let calendar = Calendar.current
        endFocusModeTime = calendar.date(byAdding: .minute, value: minute, to: Date())
        startFocusModeTime = Date()
        
        for i in 0..<arrFocusType.count{
            arrFocusType[i]["isOn"] = false
            arrFocusType[i]["isPaused"] = false
        }
        
        getTotalFocuedTime()
        //After finishing pomodoro block, clicking start another focus block doesn't use correct focus mode #741
//        startingFocusModeVcObj?.loadView()
        //
        
        if let focusModeId = arrFocusTypeForPomodoro[popUpBtnFocusType.indexOfSelectedItem]["id"] as? String{
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["id"] as? String ?? "" == focusModeId{
                    arrFocusType[i]["isOn"] = true
                    arrFocusType[i]["lastStartedDate"] = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")//
                    arrFocusType[i]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                    shouldReloadTaskPlayer = true
                    if let isAutoDoNotDisturbEnabled = arrFocusType[i]["isAutoDoNotDisturbEnabled"] as? Bool{
                        if isAutoDoNotDisturbEnabled{
                            if isAccessibilityEnabled(isPrompt: true){
                                enableDND()
                            }
                        }
                    }
                    
                    if !isDndEnabled{
                        if let isDeepWorkFocus = arrFocusType[i]["isDeepWorkFocus"] as? Bool{
                            if  isDeepWorkFocus{
                                if isAccessibilityEnabled(isPrompt: true){
                                    enableDND()
                                }
                            }
                        }else if let isDefault = arrFocusType[i]["isDefault"] as? Bool{
                            if  isDefault{
                                if isAccessibilityEnabled(isPrompt: true){
                                    enableDND()
                                }
                            }
                        }
                    }
                    
                    workBeforeFocusBegin(index: i)
                    
                    //After finishing pomodoro block, clicking start another focus block doesn't use correct focus mode #741
//                    startingFocusModeVcObj?.lastFocusModeId = focusModeId
                    //
                    
                    let oldFocusAlignmentScoreThreshold = arrFocusType[i]["focusAlignmentScoreThreshold"] as? Int ?? -1
                    let focusAlignmentScoreThreshold = Int(popUpBtnFocusAlignmentScore.titleOfSelectedItem ?? "") ?? 80
                    if oldFocusAlignmentScoreThreshold != focusAlignmentScoreThreshold{
                        arrFocusType[i]["focusAlignmentScoreThreshold"] = focusAlignmentScoreThreshold
                        allApiObject.capturePosthog(event: "focus-alignment-score-threshold-changed", metadata: [:])
                    }
                    focusModeTaskString = arrFocusType[i]["lastTaskUsed"] as? String ?? ""
                    if !textViewAchieve.string.isEmpty{
                        arrFocusType[i]["lastIntentionUsed"] = textViewAchieve.string
                    }else{
                        arrFocusType[i]["lastIntentionUsed"] = ""
                    }
                    taskCreatedByBlockPopup = ""
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    updateAllFocusModes()
                    break;
                }
            }
        }
        minFocusAlignmentScoreToShowDistractingPopUp = Double(popUpBtnFocusAlignmentScore.title) ?? 80
        if SettingsManagerObject.isDataCollectionModeEnabled{
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }
        isFocusModeRunning = true
        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusTypeForPomodoro[popUpBtnFocusType.indexOfSelectedItem]["color"] as? String ?? "")
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: textViewAchieve.string)
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        
            
        
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        
        appdelegate?.setFocusModeTimer(hour: nil, minute: minute)
        isFocusModeStartedFromPomodoroMode = true
        if isSkipMicrobreaks{
            isSkipBreakActivityDuringPomodoro = true
            addLog(text: "checkBoxSkipMicrobreaks is on in geek mode focus session.")
        }else{
            isSkipBreakActivityDuringPomodoro = false
            addLog(text: "checkBoxSkipMicrobreaks is off in geek mode focus session.")
        }
        whatToAchieveInFocusBlock = textViewAchieve.string
        appdelegate!.focusModeStartted(isStartedByPusher: false)
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled && currentState != ._MICRO_BREAK_{ // added is micro break is running :- v 2.28.438
            if isHardCorePomodoroModeOn{
                //I did this because when isHardCorePomodoroModeOn is enabled, showTaskPlayerWindow prevents viewDidAppear from being called properly. So when coming back the next time, viewWillAppear doesn’t get called, and the previous state is shown.v 2.28.440
                DispatchQueue.global().async {
                    sleep(1)
                    DispatchQueue.main.async { [self] in
                        showTaskPlayerWindow(totalDuration: minute, intention: textViewAchieve.string, automatically:true)
                    }
                }
            }else{
                showTaskPlayerWindow(totalDuration: minute, intention: textViewAchieve.string, automatically:true)
            }
            
        }else{
            if !getTaskPlayerVcObject().isViewLoaded{
                getTaskPlayerVcObject().loadView()
            }
            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: textViewAchieve.string)
            shouldReloadTaskPlayer = false
        }
        //After finishing pomodoro block, clicking start another focus block doesn't use correct focus mode #741
//        startingFocusModeVcObj?.lastIntention = textViewAchieve.string
//        startingFocusModeVcObj?.lastHourValue = 0
//        startingFocusModeVcObj?.lastMinuteValue = textFieldWorkDuration.integerValue
//        startingFocusModeVcObj?.lastSkipMicroBreakState = isSkipBreakActivityDuringPomodoro
        //
        
        if isShowingPomodoroManually{
            var type = ""
            if isHardCorePomodoroModeOn{
                type = "super-focus"
            }else{
                type = "single-focus"
            }
            allApiObject.capturePosthog(event: "start-focus-session-manually", metadata: ["type":type, "focusDuration":currentPomodoroWorkDuration, "breakDuration":currentPomodoroBreakDuration])
        }
        
    }
    @IBAction func btnCheckBoxHardcodePomodoroClicked(_ sender: Any) {
        if btnCheckBoxHardcodePomodoro.state == .on{
            lblQuestionSecond.stringValue = chooseTheFocusModeText
            stackViewPomodoroModeTime.isHidden = false
            
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
                let alertWarning = NSAlert()
                
                alertWarning.setSharingType()
                alertWarning.messageText = "To make hardcore pomodoro mode more effective, we recommend setting a password (ask someone else to do it for you) otherwise you'll still be able to cancel the focus modes before the time is up."
                if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                    if let alertWarningPaswwordSetText = pomodoroInfo.value(forKey: "alertWarningPaswwordSetText") as? String{
                        alertWarning.messageText = alertWarningPaswwordSetText
                    }
                }
                alertWarning.beginSheetModal(for: self.view.window!, completionHandler:nil)
            }
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                    isFrictionLevelHigh = true
                }
            }
        }else{
            lblQuestionSecond.stringValue = questionSecondText
            stackViewPomodoroModeTime.isHidden = true
            btnLetsDoIt.isEnabled = true
            isFrictionLevelHigh = false
        }
//        if isFrictionLevelHigh{
//            lblFrictionLevel.stringValue = frictionLevelHighText
//        }else{
//            lblFrictionLevel.stringValue = frictionLevelLowText
//        }
    }
    
    func passwordIsCorrect(){
        print("password Correct")
        isHardCorePomodoroModeOn = false
        self.view.window?.close()
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }
    override func viewWillDisappear() {
//        removeTimerMoveWindowToCenter()
        
        isIntentionFromMorningPostpone = false
        timer?.invalidate()
        timer = nil
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
        
        //Proposed focus session title text adjustment emphasizes user choices post-habit postponement, enhancing clarity. Title - What do you want to do instead of your habits?
        // setting normal title again
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            lblTitle.stringValue = pomodoroInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
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
        self.lblTimerUnfocused.stringValue = timerText.replacingOccurrences(of: "<TIME>", with: "\(hour):\(minute):\(second)")//"Time spend unfocused: \(hour):\(minute):\(second)"//
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
        if !appdelegate!.isSystemSleep && !appdelegate!.isScreenSaverStart && currentState != ._MICRO_BREAK_{
            currentTimer += 1
        }
        setProgres()
    }

    @IBAction func btnSwitchAdvancedModeClicked(_ sender: Any) {
        if btnSwitchAdvancedMode.state == .on{
            btnCheckBoxHardcodePomodoro.isHidden = false
            stackViewFocusAlignmentScore.isHidden = true
            if SettingsManagerObject.isCuddlyModeEnabled && SettingsManagerObject.isAiCheckUrlEnabled && sliderStrictness.integerValue != 3{
                stackViewFocusAlignmentScore.isHidden = false
            }
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAdvancedPomodoroEnabled)
        }else{
            btnCheckBoxHardcodePomodoro.isHidden = true
            stackViewFocusAlignmentScore.isHidden = true
            UserDefaults.standard.set(false, forKey: kUserdefaultsIsAdvancedPomodoroEnabled)
        }
    }
//    @IBAction func btnFrictionLevelInfoClicked(_ sender: Any) {
//        if isFrictionLevelHigh{
//            var msg = "You need to enter a password to stop focusing"
//            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                    msg = startingFocusModeInfo.value(forKey: "tooltipFrictionLevelHighText") as? String ?? msg
//                }
//            }
//
//            showTooltip(sender: btnFrictionLevelInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//        }else{
//            var msg = "You can stop focusing at any time"
//            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                    msg = startingFocusModeInfo.value(forKey: "tooltipFrictionLevelLowText") as? String ?? msg
//                }
//            }
//
//            showTooltip(sender: btnFrictionLevelInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//        }
//    }
    @IBAction func btnInfoPomodoroClicked(_ sender: Any) {
        if popoverInfo == nil{
            popoverInfo = NSPopover()
            popoverInfo!.behavior = .transient
            popoverInfo!.animates = false
        }
        if popoverInfo!.isShown{
            popoverInfo?.close()
        }
        let vc = getPomodoroTooltipVcObject()

        func getPomodoroTooltipVcObject()->pomodoroTooltipVc{
            if pomodoroTooltipVcObj == nil{
                pomodoroTooltipVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroTooltipVc")) as? pomodoroTooltipVc
            }
            return pomodoroTooltipVcObj!
        }
        popoverInfo!.contentViewController = vc
        popoverInfo!.contentSize = vc.view.frame.size
        
        popoverInfo!.show(relativeTo: btnInfoPomodoro.bounds, of: btnInfoPomodoro, preferredEdge: NSRectEdge.maxX)
    }

    
    @IBAction func btnEditRatioClicked(_ sender: Any) { // not in use

        
    }
    
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
            var strictnessSuperStrictClickedText = "I understand I cannot stop this focus session without a password. I am committed to avoiding distractions and getting a ton of work done."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                    strictnessSuperStrictClickedText = startingFocusModeInfo.value(forKey: "strictnessSuperStrictClickedNewText") as? String ?? strictnessSuperStrictClickedText
                }
            }
            
            showTooltip(sender: sliderStrictness, msg: strictnessSuperStrictClickedText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
        btnSwitchAdvancedModeClicked(self)
        showSelectedStrictnessLevel()
    }
    
    @IBAction func btnToggleBreaksSettingsClicked(_ sender: Any) {
        if isSkipMicrobreaks{
            btnToggleBreaksSettings.title = titleBreaksOn
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsPomodoroSkipMicroBreaks)
            isSkipMicrobreaks = false
        }else{
            btnToggleBreaksSettings.title = titleBreaksOff
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsPomodoroSkipMicroBreaks)
            isSkipMicrobreaks = true
        }
    }
    
    @IBAction func btnToggleBreaksSettingsInfoClicked(_ sender: Any) {
        var msg = "Activate micro-breaks for eye health and stretch reminders during your focus session. Every <BREAK_FREQUENCY> minutes, Focus Bear will ask you to take a short break. Then at the end of your focus session, you’ll get a longer break of <BREAK_DURATION> minutes"
        
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            msg = pomodoroInfo.value(forKey: "toggleBreaksTooltip") as? String ?? msg
        }
        msg = msg.replacingOccurrences(of: "<BREAK_FREQUENCY>", with: "\(breakAfterMinutes)")
        msg = msg.replacingOccurrences(of: "<BREAK_DURATION>", with: "\(textFieldBreakDuration.integerValue)")
        
        showTooltip(sender: btnToggleBreaksSettingsInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    
    @IBAction func btnPinClicked(_ sender: Any) {
        if self.view.window?.level == NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow))){
            self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
            btnPin.image = #imageLiteral(resourceName: "unPin")
        }else{
            self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
            btnPin.image = #imageLiteral(resourceName: "pin")
        }
    }
    
    @IBAction func btnErrorClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            let alertWarning = NSAlert()// will not execute
            alertWarning.setSharingType()
            alertWarning.messageText = "Do you want to block distractions?"
            alertWarning.informativeText = "You can block distracting websites and distracting apps. You will need to allow permissions to block distracting websites."
            var buttonBlockText = "Yeah - block them!"
            var buttonNoText = "No thanks"
            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
                alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningSetDistractionsInfo") as? String ?? alertWarning.informativeText
                buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
                buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
            }
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                
                if modalResponse == .alertFirstButtonReturn{
                    showDistractionTypesWindow(showingFromPomodoro: true)
                    self.intentionToShowAgain = self.textViewAchieve.string
                }
                
            })
        }else if !browserPermissionGiven{
            showExplainingPermissionsWindow(showingFromPomodoro: true)
            self.intentionToShowAgain = self.textViewAchieve.string
            self.view.window?.close()
        }
    }
    
    @IBAction func btnInfoStrictnessLevelClicked(_ sender: Any) {
        var msgToShow = ""
        if sliderStrictness.integerValue == 1{
            msgToShow = toolTipNormalMode
        }else if sliderStrictness.integerValue == 2{
            msgToShow = toolTipStrictMode
        }else if sliderStrictness.integerValue == 3{
            msgToShow = toolTipSuperStrictMode
        }
        
        showTooltip(sender: btnInfoStrictnessLevel, msg: msgToShow, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
}

class IntegerFormatter: NumberFormatter {
    let maxLength = 3
    
    let wrongCharacterSet = CharacterSet(charactersIn: "0123456789").inverted
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        self.maximumFractionDigits = 2
        self.minimumFractionDigits = 0
        
        if partialString.count > maxLength {
            return false
        }
        if partialString.rangeOfCharacter(from: wrongCharacterSet) != nil {
            return false
        }
        return true
    }
}



extension pomodoroVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField{
            if textField == textFieldWorkDuration{
                updateBreakDuration()
            }else if textField == textFieldBreakDuration{
                isBreakDurationComesFromBreakRatio = false
                print("isBreakDurationComesFromBreakRatio false")
            }
        }
    }
}
