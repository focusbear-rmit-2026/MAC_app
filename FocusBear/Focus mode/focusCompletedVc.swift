//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedVc: NSViewController {
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var imgViewAccordinMoreOptions: NSImageView!
    @IBOutlet weak var lblAccordinMoreOptions: NSTextField!
    @IBOutlet weak var boxAccordinMoreOptions: NSBox!
    @IBOutlet weak var stackViewMoreQuestions: NSStackView!
    @IBOutlet weak var boxAverageTabCount: NSBox!
    @IBOutlet weak var boxAverageTimeSpent: NSBox!
    @IBOutlet weak var btnMoreOptions: cursorButton!
    
    @IBOutlet weak var textFieldNextSessionIntention: shadowTextField!
    @IBOutlet weak var lblTitleNextSessionIntention: NSTextField!
    @IBOutlet weak var boxNextSessionIntention: NSBox!
    @IBOutlet weak var btnActivateTimeTracker: underLineButton!
    @IBOutlet weak var lblEnableTimeTracker: NSTextField!
    @IBOutlet weak var boxEnableTimeTracker: NSBox!
    @IBOutlet weak var btnInfoAppOrSite: hoverInfoButton!
    @IBOutlet weak var btnInfoAverageTabCount: hoverInfoButton!
    @IBOutlet weak var btnInfoAverageTimePerTab: hoverInfoButton!
    @IBOutlet weak var btnInfoTotalWotkTimeToday: hoverInfoButton!
    @IBOutlet weak var btnInfoDeepWotkTimeThisSession: hoverInfoButton!
    @IBOutlet weak var btnInfoFocusAlignment: hoverInfoButton!
    @IBOutlet weak var boxFocusAlignmentScore: NSBox!
    @IBOutlet weak var btnEnableAdvancedAnalytics: underLineButton!
    @IBOutlet weak var lblDeepWorkTimeToday: NSTextField!
    @IBOutlet weak var lblTitleTime: NSTextField!
    @IBOutlet weak var lblTitleAppOrSite: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblAverageTimeSpentPerTab: NSTextField!
    @IBOutlet weak var lblDeepFocusTime: NSTextField!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var lblTitleAverageTimeSpentPerTab: NSTextField!
    @IBOutlet weak var lblTitleDeepWorkTime: NSTextField!
    @IBOutlet weak var lblTitleDeepWorkTimeToday: NSTextField!
    
    @IBOutlet weak var lblTabCount: NSTextField!
    @IBOutlet weak var lblTitleTabCount: NSTextField!
    
    @IBOutlet weak var lblTitleFocusAlignmentScore: NSTextField!
    @IBOutlet weak var lblTitleStats: NSTextField!

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
    @IBOutlet weak var textFieldDistractions: NSTextField!// hidden
    @IBOutlet weak var textFieldAchieve: NSTextField!
    @IBOutlet weak var btnStartAnotherFocusBlock: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var btnTakeBreak: underLineButton!
    @IBOutlet weak var lblIntentionWas: NSTextField!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet weak var boxBlankSpaceInsideMoreQuestions: NSBox!
    
    var currentFocusModeName = ""
    var subtitle = "Focus block complete – log your achievement to track progress!"
    var buttonTakeBreakText = "Relax 5 minutes"
    var currentFocusModeId = ""
    var finish_time:Date?
    var isShutOffTime = false
    var arrAllTags = [String]()
    var defaultTokenMenu = NSMenu()
    var currentFocusModeIndex = 0
    
    let popoverMenuTour = NSPopover()
//    var timerMoveWindowToCenter:Timer?
    
    var menuTourPopoverVcObj: menuTourPopoverVc?
    var currentIndex = 0
    var pinButtonTrackingArea: NSTrackingArea?
    var breakMinute: Int = 5
    var arrAllAppsTabsData = [[String:Any]]()
    var allowExtend = false
    var isFinishFocusModeApiCalled = false
    
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    var arrTourMessages:[[String:Any]] = [["title": "Intention", "description": "See what intentions have you set when starting the focus block.", "buttonTitle": "Next"],
                           ["title": "Achivements", "description": "Write a summary of what did you achieved during this focus block.", "buttonTitle": "Next"],
                           ["title": "Reporting Tags", "description": "Add reporting tags to help analyse your time logs. For example, you could add a \"billable\" tag if you're a freelancer or add tags for certain clients.", "buttonTitle": "Next"],
                           ["title": "Distractions", "description": "Did you faced any distractions? Write a summary of distractions faced.", "buttonTitle": "Finish"]]
    
    let kUserdefaultsShowTextForTokenFieldFirstTime = "kUserdefaultsShowTextForTokenFieldFirstTime"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnPin.image = #imageLiteral(resourceName: "pin")
        tokenFieldTags.delegate = self
        btnEnableAdvancedAnalytics.titleColor = NSColor.systemBlue
        btnMoreOptions.title = "More Stats"
        lblAccordinMoreOptions.stringValue = "✨ Log your Achievement"
        
        // CTA styling improvement (Issue #1489)
        // Improves visibility, contrast, and aligns with Focus Bear orange theme
        // Text
        lblAccordinMoreOptions.textColor = NSColor.systemOrange
        lblAccordinMoreOptions.font = NSFont.systemFont(ofSize: 18, weight: .semibold)

        // Container
        boxAccordinMoreOptions.wantsLayer = true
        boxAccordinMoreOptions.boxType = .custom
        boxAccordinMoreOptions.fillColor = .clear
        boxAccordinMoreOptions.isTransparent = true

        boxAccordinMoreOptions.layer?.cornerRadius = 10
        boxAccordinMoreOptions.layer?.borderWidth = 1

        if let appearance = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) {
            if appearance == .darkAqua {
                // Dark mode
                boxAccordinMoreOptions.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.18).cgColor
                boxAccordinMoreOptions.layer?.borderColor = NSColor.systemOrange.withAlphaComponent(0.45).cgColor
            } else {
                // Light mode
                boxAccordinMoreOptions.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.22).cgColor
                boxAccordinMoreOptions.layer?.borderColor = NSColor.systemOrange.withAlphaComponent(0.5).cgColor
            }
        }
        
        lblEnableTimeTracker.stringValue = "Want to get even deeper analytics?"
        btnActivateTimeTracker.title = "Activate Focus Bear Time Tracker"
        lblTitleNextSessionIntention.stringValue = "What do you plan to do next?"
        
        lblTitleStats.stringValue = "Stats"
        lblTitleFocusAlignmentScore.stringValue = "Focus Alignment Score"
        lblTitleDeepWorkTime.stringValue = "Deep work time this session"
        lblTitleDeepWorkTimeToday.stringValue = "Total deep work time today"
        lblTitleAverageTimeSpentPerTab.stringValue = "Average Time Spent per Tab/App"
        lblTitleTabCount.stringValue = "Average tab count"
        lblTitleAppOrSite.stringValue = "App or site"
        lblTitleTime.stringValue = "Time"
        btnEnableAdvancedAnalytics.title = "Enable advanced analytics"
        
        btnDoBreakActivity.title = "Do break habits"
        lblTitleTags.stringValue = "Reporting Tags"
        btnStartAnotherFocusBlock.title = "Start new focus session"

        lblTitle.stringValue = "You did it!"
        lblQuestionFirst.stringValue = "What did you achieve during this session?"
        lblQuestionSecond.stringValue = "How focused were you?"
        lblIntentionWas.stringValue = "Your intention was"
        
        
        var tourTitleStarRating = "Rate Your session"
        var tourSubTitleStarRating = "Stored in your focus session log so you can look back at what you achieved."
        var tourTitleNextGoal = "Next session goal"
        var tourSubTitleNextGoal = "Set your focus goal for your next session"
        
        var titleTourBox = "Focus Complete Block"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                if let title = focusCompletedInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = focusCompletedInfo.value(forKey: "subtitleNew") as? String{
                    self.subtitle = subTitle
                }
                if let questionFirstText = focusCompletedInfo.value(forKey: "questionFirstText") as? String{
                    lblQuestionFirst.stringValue = questionFirstText
                }
                
                // Fix wording (Issue #1489)
                lblQuestionFirst.stringValue = "What did you achieve during this session?"
                
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
                
                
                lblTitleStats.stringValue = focusCompletedInfo.value(forKey: "titleStats") as? String ?? lblTitleStats.stringValue
                lblTitleFocusAlignmentScore.stringValue = focusCompletedInfo.value(forKey: "titleFocusAlignmentScore") as? String ?? lblTitleFocusAlignmentScore.stringValue
                lblTitleDeepWorkTime.stringValue = focusCompletedInfo.value(forKey: "titleDeepWorkTime") as? String ?? lblTitleDeepWorkTime.stringValue
                lblTitleDeepWorkTimeToday.stringValue = focusCompletedInfo.value(forKey: "titleDeepWorkTimeToday") as? String ?? lblTitleDeepWorkTimeToday.stringValue
                lblTitleAverageTimeSpentPerTab.stringValue = focusCompletedInfo.value(forKey: "titleTimeSpentPerTab") as? String ?? lblTitleAverageTimeSpentPerTab.stringValue
                lblTitleTabCount.stringValue = focusCompletedInfo.value(forKey: "titleTabCount") as? String ?? lblTitleTabCount.stringValue
                lblTitleAppOrSite.stringValue = focusCompletedInfo.value(forKey: "titleAppOrSite") as? String ?? lblTitleAppOrSite.stringValue
                lblTitleTime.stringValue = focusCompletedInfo.value(forKey: "titleTime") as? String ?? lblTitleTime.stringValue
                btnEnableAdvancedAnalytics.title = focusCompletedInfo.value(forKey: "buttonEnableAdvancedAnalyticsText") as? String ?? btnEnableAdvancedAnalytics.title
                lblEnableTimeTracker.stringValue = focusCompletedInfo.value(forKey: "askEnableTimeTrackerText") as? String ?? lblEnableTimeTracker.stringValue
                btnActivateTimeTracker.title = focusCompletedInfo.value(forKey: "buttonActivateTimeTrackerText") as? String ?? btnActivateTimeTracker.title
                lblTitleNextSessionIntention.stringValue = focusCompletedInfo.value(forKey: "titleNextSessionIntention") as? String ?? lblTitleNextSessionIntention.stringValue
                btnMoreOptions.title = focusCompletedInfo.value(forKey: "buttonMoreOptionsText") as? String ?? btnMoreOptions.title
                lblAccordinMoreOptions.stringValue = focusCompletedInfo.value(forKey: "buttonAccordionAchievement") as? String ?? lblAccordinMoreOptions.stringValue
                
                // CTA styling improvement (Issue #1489)
                // Improves visibility, contrast, and aligns with Focus Bear orange theme
                // Text
                lblAccordinMoreOptions.textColor = NSColor.systemOrange
                lblAccordinMoreOptions.font = NSFont.systemFont(ofSize: 18, weight: .semibold)

                // Container
                boxAccordinMoreOptions.wantsLayer = true
                boxAccordinMoreOptions.boxType = .custom
                boxAccordinMoreOptions.fillColor = .clear
                boxAccordinMoreOptions.isTransparent = true

                boxAccordinMoreOptions.layer?.cornerRadius = 10
                boxAccordinMoreOptions.layer?.borderWidth = 1

                if let appearance = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) {
                    if appearance == .darkAqua {
                        // Dark mode
                        boxAccordinMoreOptions.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.18).cgColor
                        boxAccordinMoreOptions.layer?.borderColor = NSColor.systemOrange.withAlphaComponent(0.45).cgColor
                    } else {
                        // Light mode
                        boxAccordinMoreOptions.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.22).cgColor
                        boxAccordinMoreOptions.layer?.borderColor = NSColor.systemOrange.withAlphaComponent(0.5).cgColor
                    }
                }
                
                tourTitleStarRating = focusCompletedInfo.value(forKey: "tourTitleStarRating") as? String ?? tourTitleStarRating
                tourSubTitleStarRating = focusCompletedInfo.value(forKey: "tourSubTitleStarRating") as? String ?? tourSubTitleStarRating
                tourTitleNextGoal = focusCompletedInfo.value(forKey: "tourTitleNextGoal") as? String ?? tourTitleNextGoal
                tourSubTitleNextGoal = focusCompletedInfo.value(forKey: "tourSubTitleNextGoal") as? String ?? tourSubTitleNextGoal
            }
        }
        

        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
        }
        
        arrTourMessages.remove(at: 3) //remove distractions
        arrTourMessages.append(["title": tourTitleStarRating,
                                "description": tourSubTitleStarRating])
        
        for i in 0..<arrTourMessages.count{
            if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
            
            if i == 0{
                arrTourMessages[i]["view"] = lblIntentionWas
            }else if i == 1{
                arrTourMessages[i]["view"] = textFieldAchieve
            }else if i == 2{
                arrTourMessages[i]["view"] = tokenFieldTags
            }else if i == 3{
                arrTourMessages[i]["view"] = lblQuestionSecond
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
        btnStartAnotherFocusBlock.isSecondaryButton = true
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
 
        
        if !isFocusModeRunning{
            if !isFinishFocusModeApiCalled{
                whatToAchieveInFocusBlock = ""

                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                
                let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
                let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
                
                for i in 0..<arrFocusType.count{// clear datat after focus completed
                    arrFocusType[i]["lastStartedDate"] = nil
                    arrFocusType[i]["lastScheduledEndDate"] = nil
                }
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                
                updateAllFocusModeTags()
                addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "", tags:getTagsString())

                isFinishFocusModeApiCalled = true
                allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), rating:currentRatingCount, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        if self.isShutOffTime{
                            currentState = ._NOTHING_
                            appdelegate?.shutOffMac()
                        }
                    }
                })
                addEntryInUsageTimingsExplanationCsv()
                
                focusModeFinishedResetAllData()
                nextFocusSessionIntention = textFieldNextSessionIntention.stringValue
                completedPomodoroCountInHardcorePomodoro += 1
                totalMinutesRemainingForHardcodePomodoro = 0
                isHardCorePomodoroModeOn = false
                
                if isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
                    if getHabitsVcObject().breakTimer != nil{
                        getHabitsVcObject().setActivityTimer()
                    }
                }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
                    if getHabitsVcObject().breakTimer != nil{
                        getHabitsVcObject().setActivityTimer()
                    }
                }
            }
            
        }
    }
    
    override func viewWillAppear() {
        isFinishFocusModeApiCalled = false
        loader.isHidden = true
        if isHardCorePomodoroModeOn{
            btnStartAnotherFocusBlock.isHidden = true
        }else{
            btnStartAnotherFocusBlock.isHidden = false
        }
        
        // There was a bug where, if a focus session was running when the morning routine was about to start, the Force Completed Focus view appeared before the morning habit’s first screen or the focus summary screen. In this state, if the user navigated to the Help tab and then returned to the Habits tab, the btnStartAnotherFocusBlock button became visible because the resetData() function was not called again.
        //  To prevent this issue, we are applying the solution below.  2.28.445
        if isShutOffTime || currentState == ._MORNING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
            if (leftMenuVcObj?.boxHabits.isSelected ?? false) || (leftMenuVcObj?.boxCustomRoutine.isSelected ?? false){
                btnStartAnotherFocusBlock.isHidden = true
            }
        }
        
        if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app") && UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool == true{// show tags box if time tracker is enabled
            boxTags.isHidden = false
        }else{
            boxTags.isHidden = true
        }
    }
    
    override func viewDidAppear() {
        
        
        tabMatricsObject.closeLastDomainIfStarted()
        tabMatricsObject.closeLastAppIfStarted()
        
        print(tabMatricsObject.arrAllAppsRecodDuringFocusMode)
        print(tabMatricsObject.arrAllUrlsRecodDuringFocusMode)

        arrAllAppsTabsData.removeAll()
        
        var arrAllUrlsRecodDuringFocusMode = tabMatricsObject.arrAllUrlsRecodDuringFocusMode
        var arrAllAppsRecodDuringFocusMode = tabMatricsObject.arrAllAppsRecodDuringFocusMode
        

        arrAllAppsRecodDuringFocusMode = tabMatricsObject.clubAllSameAppEntries(appData: arrAllAppsRecodDuringFocusMode)
        arrAllUrlsRecodDuringFocusMode = tabMatricsObject.clubAllSameDomainEntries(appData: arrAllUrlsRecodDuringFocusMode)
        arrAllAppsTabsData = arrAllAppsRecodDuringFocusMode
        arrAllAppsTabsData += arrAllUrlsRecodDuringFocusMode
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            arrAllAppsTabsData = arrAllAppsTabsData.sorted { dict1, dict2 in
                guard let duration1 = dict1[tabMatricsObject.keyFocusDuration] as? Int,
                      let duration2 = dict2[tabMatricsObject.keyFocusDuration] as? Int else {
                    return false
                }
                return duration1 > duration2
            }
            
            btnEnableAdvancedAnalytics.isHidden = true
            
            if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool != true{// show tags box if time tracker is enabled
                if SettingsManagerObject.isGeekModeEnabled{
                    boxEnableTimeTracker.isHidden = false
                }else{
                    boxEnableTimeTracker.isHidden = true
                }
            }else{
                boxEnableTimeTracker.isHidden = true
            }
        }else{
            btnEnableAdvancedAnalytics.isHidden = false
            boxEnableTimeTracker.isHidden = true
        }
        
        tblView.reloadData()// need to reload always
    
        lblFocusAlignmentScore.stringValue = "\(currentFocusAlignmentScore)%"
        let arrAllTabsCount = tabMatricsObject.arrAllTabsCount
        let sumOfCount =  arrAllTabsCount.reduce(0, +)
        if arrAllTabsCount.count > 0{
            let average = sumOfCount / arrAllTabsCount.count
            lblTabCount.stringValue = "\(average)"
        }else{
            lblTabCount.stringValue = "0"
        }
        
        let duration = Double(focusModeActualDurationPerformed) 
        var finalDuration = duration
        if SettingsManagerObject.isAiCheckUrlEnabled{
            boxFocusAlignmentScore.isHidden = false
            let score = currentFocusAlignmentScore
            let deepWorkDurationForAlignmentScore = (duration * score) / 100
            lblDeepFocusTime.stringValue = getStringTimeFromSeconds(seconds: Int(deepWorkDurationForAlignmentScore))
            finalDuration = deepWorkDurationForAlignmentScore
        }else{
            boxFocusAlignmentScore.isHidden = true
            lblDeepFocusTime.stringValue = getStringTimeFromSeconds(seconds: Int(duration))
        }
        
        
        let totalDeepFocusedTimeToday = totalDeepFocusedTime + finalDuration
        lblDeepWorkTimeToday.stringValue = getStringTimeFromSeconds(seconds: Int(totalDeepFocusedTimeToday))
        
        
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
            }
            return total
        }

        let averageDuration = allAppsWithoutBrowsers.isEmpty ? 0 : totalDuration / allAppsWithoutBrowsers.count
        lblAverageTimeSpentPerTab.stringValue = getStringTimeFromSeconds(seconds: averageDuration)
        
        
        
        if !focusModeTaskStringIsEmpty() || allowExtend{
            let obj = getAddTaskVcObject()
            obj.loadView()
            if self.view.window != nil{
                obj.reloadData(isAddingTask: false, allowExtend: allowExtend, isHabitGoing: false)
                if self.view.window != nil{
                    self.presentAsSheet(obj)
                }
            }
            allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-shown", metadata: [:])
        }
        btnPin.isHidden = true
        reloadMoreOptionsState()
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
                    showTooltip(sender: btnPin, msg: pinWindowText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
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
    
//    override func viewDidDisappear() {
//        removeTimerMoveWindowToCenter()
//    }
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here 
        btnStartAnotherFocusBlock.title = btnStartAnotherFocusBlock.title
        btnDoBreakActivity.title = btnDoBreakActivity.title
    }
    
    func resetData(focusModeName:String, currentFocusModeId:String, finish_time:Date, isShutOffTime:Bool){
        nextFocusSessionIntention = ""
        textFieldNextSessionIntention.stringValue = ""
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
        
        /* lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)//"You have successfully completed the focus block - \(currentFocusModeName)" */
        // Override config subtitle for improved UX (Issue #1489)
        lblSubTitle.stringValue = subtitle
        textViewIntention.string = whatToAchieveInFocusBlock.removingPercentEncoding ?? whatToAchieveInFocusBlock
        if !focusModeTaskStringIsEmpty(){
            let focusModeTaskString = getFocusModeTaskString()
            if !whatToAchieveInFocusBlock.isEmpty{
                textViewIntention.string = focusModeTaskString + "\n" + (whatToAchieveInFocusBlock.removingPercentEncoding ?? "")
            }else{
                textViewIntention.string = focusModeTaskString
            }
        }
        
        
        lblIntentionWas.stringValue = "Your intention was"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                if let titleIntention = focusCompletedInfo.value(forKey: "titleIntention") as? String{
                    lblIntentionWas.stringValue = titleIntention
                }
            }
        }
        lblIntentionWas.stringValue = lblIntentionWas.stringValue + ": " + textViewIntention.string.replacingOccurrences(of: "\n", with: ". ")
        lblIntentionWas.toolTip = lblIntentionWas.stringValue
        
        btnTakeBreak.isEnabled = true
        loader.isHidden = true
        boxNextSessionIntention.isHidden = true
        if isShutOffTime || currentState == ._MORNING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
            btnTakeBreak.title = "Continue"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                btnTakeBreak.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnTakeBreak.title
            }
            btnStartAnotherFocusBlock.isHidden = true
            
            // Remove Next Plan section (Issue #1489)
            /* boxNextSessionIntention.isHidden = true */
        }else{
            
            // Remove Next Plan section (Issue #1489)
            /* boxNextSessionIntention.isHidden = false */
            if isHardCorePomodoroModeOn{
                btnStartAnotherFocusBlock.isHidden = true
            }else{
                btnStartAnotherFocusBlock.isHidden = false
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
                            if workRatio <= 0{
                                workRatio = 1
                                UserDefaults.standard.set(workRatio, forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro)
                            }
                        }
                        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro) as? Int{
                            breakRatio = ratio
                            if breakRatio <= 0{
                                breakRatio = 1
                                UserDefaults.standard.set(breakRatio, forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro)
                            }
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
            
            if isMicroBreaksRunning(){
                btnTakeBreak.title = "Continue Break"
                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                    if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                        btnTakeBreak.title = focusCompletedInfo.value(forKey: "buttonContinueMicroBreak") as? String ?? btnTakeBreak.title
                    }
                }
            }else{
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
            
            
            
        }
        
        if currentState != ._MORNING_HABIT_ && currentState != ._MICRO_BREAK_ && currentState != ._EVENING_HABIT_ && currentState != ._CUSTOM_ROUTINE_ && (isHabitAlreadyShowed || currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ || currentState == ._POSTPONE_EVENING_HABIT_) && arrAllbreakActivities.count != 0 && (!isShutOffTimeGoing() || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_) && !isHardCorePomodoroModeOn{
            btnDoBreakActivity.isHidden = false
        }else{
            btnDoBreakActivity.isHidden = true
        }
        
        reloadMoreOptionsState()
        reloadMoreQuestionsState()
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
        isFinishFocusModeApiCalled = true
        whatToAchieveInFocusBlock = ""
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        
        for i in 0..<arrFocusType.count{// clear datat after focus completed
            arrFocusType[i]["lastStartedDate"] = nil
            arrFocusType[i]["lastScheduledEndDate"] = nil
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        updateAllFocusModeTags()
       

        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "", tags:getTagsString())

        
        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), rating:currentRatingCount, completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })
        addEntryInUsageTimingsExplanationCsv()
        focusModeFinishedResetAllData()
        nextFocusSessionIntention = textFieldNextSessionIntention.stringValue
        
        if isMicroBreaksRunning(){// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
            self.view.window?.close()
        }
        
        if currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._CUSTOM_ROUTINE_{// focus end screen was showing before starting  a routine
            addLog(text: "focusCompletedVc - Start Another Focus Mode cancelled reason:- (sutofftime or morning routine time")//
            return;
        }
        
        
        if !SettingsManagerObject.isGeekModeEnabled{
            appdelegate?.menuShowSimplePomodoroModeView()
        }else{
            appdelegate?.menuShowPomodoroModeView()
        }
    }
    
    func workDone(){
        isFinishFocusModeApiCalled = true// perfect place this will ensure that api will called 100%
        whatToAchieveInFocusBlock = ""
        if !isShutOffTime{
            if currentState != ._MORNING_HABIT_ && currentState != ._CUSTOM_ROUTINE_ && isMicroBreaksRunning(){
                if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
                    if !notes.isEmpty{
                        showBrainDumpWindow()
                    }
                }
            }
            
        }else{
            btnTakeBreak.isEnabled = false
            loader.isHidden = false
            loader.startAnimation(self)
        }
        
        
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        
        for i in 0..<arrFocusType.count{// clear datat after focus completed
            arrFocusType[i]["lastStartedDate"] = nil
            arrFocusType[i]["lastScheduledEndDate"] = nil
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
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
        
        
        addEntryInUsageTimingsExplanationCsv()
        
        focusModeFinishedResetAllData()
        nextFocusSessionIntention = textFieldNextSessionIntention.stringValue
        
        let minutes = currentPomodoroWorkDuration
        completedPomodoroCountInHardcorePomodoro += 1
        
      
        if isFocusModeStartedFromPomodoroMode{
            if !isShutOffTime && currentState != ._MORNING_HABIT_ && currentState != ._CUSTOM_ROUTINE_{
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
            if getHabitsVcObject().breakTimer != nil{
                getHabitsVcObject().setActivityTimer()
            }
        }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
            if getHabitsVcObject().breakTimer != nil{
                getHabitsVcObject().setActivityTimer()
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
        if currentState == ._POSTPONE_MORNING_HABIT_{
            isBreakActivityExecuteFromPostponeMorningHabit = true
        }
        if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
            isBreakActivityExecuteFromPostponeEveningHabit = true
        }
        if !isMainWindowLoaded{
            mainWindowControllerObj?.loadWindow()
        }
        getHabitsVcObject().executeBreakActivities()
        shouldShowPomodoroAfterBreak = true
        shouldEndPomodoroBreakAtTime = Date().addingTimeInterval(TimeInterval(60*self.breakMinute))
    }
    
    func closeWindowForcefully(){
        if !isFinishFocusModeApiCalled{
            isFinishFocusModeApiCalled = true
            whatToAchieveInFocusBlock = ""

            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            
            let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
            let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
            
            for i in 0..<arrFocusType.count{// clear datat after focus completed
                arrFocusType[i]["lastStartedDate"] = nil
                arrFocusType[i]["lastScheduledEndDate"] = nil
            }
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            
            updateAllFocusModeTags()
            addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "", tags:getTagsString())

            allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), rating:currentRatingCount, completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
            addEntryInUsageTimingsExplanationCsv()
            
            focusModeFinishedResetAllData()
            nextFocusSessionIntention = textFieldNextSessionIntention.stringValue
            completedPomodoroCountInHardcorePomodoro += 1
            totalMinutesRemainingForHardcodePomodoro = 0
            isHardCorePomodoroModeOn = false
            
            if isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
                if getHabitsVcObject().breakTimer != nil{
                    getHabitsVcObject().setActivityTimer()
                }
            }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
                if getHabitsVcObject().breakTimer != nil{
                    getHabitsVcObject().setActivityTimer()
                }
            }
            
            self.view.window?.close()
        }
        
    }
    
    @IBAction func btnTakeBreakClicked(_ sender: Any) {
        takeBreakClicked(isCloseWindowClicked: false)
    }
    
    func takeBreakClicked(isCloseWindowClicked:Bool){
        if isCloseWindowClicked{
            addLog(text: "[user-action] focusCompletedVc - closeWindowClicked")
        }else{
            addLog(text: "[user-action] focusCompletedVc - btnRelaxClicked")
        }
        
        workDone()
        
        if currentState != ._MORNING_HABIT_ && !isMicroBreaksRunning() && currentState != ._EVENING_HABIT_ && currentState != ._CUSTOM_ROUTINE_ && (isHabitAlreadyShowed || currentState == ._POSTPONE_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !isShutOffTimeGoing() && !isHardCorePomodoroModeOn{
            if !isCloseWindowClicked{
                appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*self.breakMinute))
                if isAppEnable{
                    isFocusBreakOn = true
                }
                
                showSmallTimerWindow(durationSeconds: 60*self.breakMinute, msg: "", isFocusBreak: true, currentTimerValue:0)
            }
            self.view.window?.close()
            if lastFocusModeTempInfo != nil{
                showaddFocusTempUrlsOrAppsWindow()
            }
            
        }else{
            windowClose(isCloseWindowClicked: isCloseWindowClicked)
            
            func windowClose(isCloseWindowClicked:Bool){
                if currentState == ._MORNING_HABIT_{
                    if self == focusCompletedVcObj{//normal case
                        self.view.window?.close()// focus end screen was showing before starting  a routine
                    }else{
                        currentState = ._NOTHING_
                        if appdelegate?.isUserOnMeeting ?? false{
                            // Added on 21/04/26 (v3.31.472):
                            // Handle case where a meeting is detected after the morning routine has started, since the first screen is force completes the focus session.
                            // skip the morning routine flow and close related UI
                            mainWindowControllerObj?.window?.close()
                            hideBlankWindowInSecondaryMonitor()
                            leftMenuVcObj?.habitOver()
                        }else{
                            btnTakeBreak.isEnabled = false
                            loader.isHidden = false
                            loader.startAnimation(self)
                            appdelegate!.backgroundThread()
                        }
                    }
                    isHardCorePomodoroModeOn = false
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if self == focusCompletedVcObj{//normal case
                        self.view.window?.close()// focus end screen was showing before starting  a routine
                    }else{
                        currentState = ._NOTHING_
                        btnTakeBreak.isEnabled = false
                        loader.isHidden = false
                        loader.startAnimation(self)
                        startCustomRoutine(index: currentRoutineIndex, isOnDemand:false)
                    }
                    isHardCorePomodoroModeOn = false
                }else if isMicroBreaksRunning(){// microbreask running and focus mode finished v 2.28.436
                    if self == focusCompletedVcObj{//normal case
                        leftMenuVcObj?.showBreaksView()
                        if !isCloseWindowClicked || isHardCorePomodoroModeOn{
                            appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*breakMinute))
                            if isAppEnable{
                                isFocusBreakOn = true
                            }
                        }
                    }
                }else if !isShutOffTime && currentState != ._MORNING_HABIT_{
                    if currentState == ._FOCUS_SUMMARY_ || currentState == ._EVENING_HABIT_{// focus end screen was showing before starting  a routine or before shutOff time
                        self.view.window?.close()
                        isHardCorePomodoroModeOn = false
                    }else{
                        if isFocusModeStartedFromPomodoroMode{
                            if !isCloseWindowClicked || isHardCorePomodoroModeOn{
                                appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(60*breakMinute))
                                if isAppEnable{
                                    isFocusBreakOn = true
                                }
                            }
                        }
                        
                        if !isCloseWindowClicked || isHardCorePomodoroModeOn{
                            showSmallTimerWindow(durationSeconds: 60*breakMinute, msg: "", isFocusBreak: true, currentTimerValue:0)
                        }
                        
                        if isHardCorePomodoroModeOn && UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool == true{
                            showSavedSitesForLaterWindowForBreaks()
                        }
                        
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
    
    @IBAction func btnEnableAdvancedAnalyticsClicked(_ sender: Any){
        if SettingsManagerObject.isGeekModeEnabled{
            
            addLog(text: "[user-action] btnEnableAdvancedAnalyticsClicked")
            leftMenuVcObj?.showSettingsView()
            if settingsSideBarVcObj != nil{
                settingsSideBarVcObj!.tblView.selectRowIndexes(IndexSet(arrayLiteral: settingsSideBarVcObj!.advancedSettingsIndex), byExtendingSelection: false)
                settingsContainerVcObj?.showPrivacyView()
                getPrivacyVcObject().highlightAdvanceAanalyticsItemBox()
            }
            
            
            NSApplication.shared.activate(ignoringOtherApps: true)
        }else{
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "This option is available in Geek mode only"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    alert.messageText = focusCompletedInfo.value(forKey: "settingNotAvailableText") as? String ?? alert.messageText
                }
            }
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
                
                
            })
        }
    }
    
    @IBAction func btnInfoFocusAlignmentClicked(_ sender: NSButton) {
        var msg = ""
        if SettingsManagerObject.isAiCheckUrlEnabled{
            msg = "The % of the focus session that you spent on productive sites/apps based on Focus Bear's AI."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    msg = focusCompletedInfo.value(forKey: "tooltipFocusAlignmentScoreAi") as? String ?? msg
                }
            }
        }else{
            msg = "The % of the focus session that you spent on productive sites/apps based on your list of blocked/allowed sites."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    msg = focusCompletedInfo.value(forKey: "tooltipFocusAlignmentScore") as? String ?? msg
                }
            }
        }

        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoDeepWotkTimeThisSessionClicked(_ sender: NSButton) {
        var msg = "We multiply the focus session duration by the focus alignment score to get your deep work time"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipDeepWotkTimeThisSession") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoTotalWotkTimeTodayClicked(_ sender: NSButton) {
        var msg = "Total deep work time accumulated from all focus sessions today, calculated using session duration and focus alignment score."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipTotalWotkTimeToday") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAverageTimePerTabClicked(_ sender: NSButton) {
        var msg = "Focus Bear keeps track of how much time you spend in each browser tab. If you are constantly changing tabs, it indicates that you're probably multi tasking rather than sticking to one task."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAverageTimePerTab") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAverageTabCountClicked(_ sender: NSButton) {
        var msg = "If you have a lot of tabs open, you're likely to get distracted by half finished work. Put the tasks in your to do list instead. Use Focus Bear's tab limiter feature to help avoid tab overwhelm."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAverageTabCount") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnActivateTimeTrackerClicked(_ sender: Any) {
        addLog(text: "[user-action] btnActivateTimeTrackerClicked")
        leftMenuVcObj?.showSettingsView()
        
        if settingsSideBarVcObj != nil{
            settingsSideBarVcObj!.tblView.selectRowIndexes(IndexSet(arrayLiteral: settingsSideBarVcObj!.advancedSettingsIndex), byExtendingSelection: false)
            settingsContainerVcObj?.showAddOnsView()
            getAddOnsVcObject().highlightTimeTrackerEnableItemBox()
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @IBAction func btnInfoAppOrSiteClicked(_ sender: NSButton) {
        var msg = "This shows your top 5 apps/sites during this focus session. Data is only stored locally on your computer."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAppOrSite") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnMoreOptionsClicked(_ sender: Any) {
        if boxAverageTimeSpent.isHidden{
            expandMoreOptions()
            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusStatsExpanded)
        }else{
            collapseMoreOptions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusStatsExpanded)
        }
    }
    
    func reloadMoreOptionsState(){
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFocusStatsExpanded) as? Bool{
            if val{
                expandMoreOptions()
            }else{
                collapseMoreOptions()
            }
        }else{
            collapseMoreOptions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusStatsExpanded)
        }
    }
    
    func expandMoreOptions(){
        boxAverageTimeSpent.isHidden = false
        boxAverageTabCount.isHidden = false
        if SettingsManagerObject.isAiCheckUrlEnabled{
            boxFocusAlignmentScore.isHidden = false
        }else{
            boxFocusAlignmentScore.isHidden = true
        }
        btnMoreOptions.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
    }
    
    func collapseMoreOptions(){
        boxFocusAlignmentScore.isHidden = true
        boxAverageTimeSpent.isHidden = true
        boxAverageTabCount.isHidden = true
        btnMoreOptions.image = NSImage(named: NSImage.touchBarGoForwardTemplateName)
    }
    
    @IBAction func btnViewAccordinMoreOptionsClicked(_ sender: Any) {
        if stackViewMoreQuestions.isHidden{
            expandMoreQuestions()
            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusAllThingsExpanded)
            DispatchQueue.global().async {
                usleep(50000)
                DispatchQueue.main.async {
                    self.scrollView.scrollToLast()
                }
                usleep(50000)
                DispatchQueue.main.async { [self] in
                    if UserDefaults.standard.object(forKey: kUserdefaultsFocusCompletedTourShown) == nil{
                        
                        if boxTags.isHidden && arrTourMessages.count > 2{
                            arrTourMessages.remove(at: 2)// remove tags tour
                        }
                        var buttonNextText = "Next >"
                        var buttonFinishText = "Finish"

                        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
                            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
                            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
                        }
                        for i in 0..<arrTourMessages.count{
                            if i == arrTourMessages.count - 1{
                                arrTourMessages[i]["buttonTitle"] = buttonFinishText
                            }else{
                                arrTourMessages[i]["buttonTitle"] = buttonNextText
                            }
                        }
                        
                        let tour = arrTourMessages[currentIndex]
                        if let view = tour["view"] as? NSView{
                            if self.view.window == nil{
                                print("widow was nil so returning ****************")
                                return;
                            }
                            popoverMenuTour.show(relativeTo: view.bounds, of: view, preferredEdge: NSRectEdge.minX)
                            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentIndex + 1)")
                            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
                            menuTourPopoverVcObj?.showCurrentMessage(title: tour["title"] as? String ?? "", description: tour["description"] as? String ?? "", buttonTitle: tour["buttonTitle"] as? String ?? "", indexText: currentIndexText, arrList: [], progress: currentIndex + 1, progressMaxValue: arrTourMessages.count)
                        }
                        
                        
                        UserDefaults.standard.set(true, forKey: kUserdefaultsFocusCompletedTourShown)
                    }
                }
            }
        }else{
            collapseMoreQuestions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusAllThingsExpanded)
        }
    }
    
    
    func collapseMoreQuestions(){
        stackViewMoreQuestions.isHidden = true
        imgViewAccordinMoreOptions.image = NSImage(named: NSImage.goForwardTemplateName)
        boxBlankSpaceInsideMoreQuestions.isHidden = false
        boxBlankSpaceInsideMoreQuestions.setFrameSize(NSSize(width: boxBlankSpaceInsideMoreQuestions.frame.width, height: 20))
    }
    
    func expandMoreQuestions(){
        stackViewMoreQuestions.isHidden = false
        imgViewAccordinMoreOptions.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
        boxBlankSpaceInsideMoreQuestions.isHidden = true
    }
    
    func reloadMoreQuestionsState(){
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFocusAllThingsExpanded) as? Bool{
            if val{
                expandMoreQuestions()
            }else{
                collapseMoreQuestions()
            }
        }else{
            collapseMoreQuestions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusAllThingsExpanded)
        }
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
        if currentIndex < arrTourMessages.count{
            let tour = arrTourMessages[currentIndex]
            if let view = tour["view"] as? NSView{
                popoverMenuTour.show(relativeTo: view.bounds, of: view, preferredEdge: NSRectEdge.minX)
                var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentIndex + 1)")
                currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
                menuTourPopoverVcObj?.showCurrentMessage(title: tour["title"] as? String ?? "", description: tour["description"] as? String ?? "", buttonTitle: tour["buttonTitle"] as? String ?? "", indexText: currentIndexText, arrList: [], progress: currentIndex + 1, progressMaxValue: arrTourMessages.count)
            }else{
                popoverMenuTour.close()
            }
        }else{
            popoverMenuTour.close()
        }
    }
    func buttonCloseClicked() {
        popoverMenuTour.close()
    }
    
    func getStringTimeFromSeconds(seconds : Int)->String{
        if seconds == 0{
            return "0" + secondsSText
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
        var stringTime: String = ""
        if h != 0{
            stringTime = "\(h)" + hoursHText
        }
        if m != 0{
            if stringTime.isEmpty{
                stringTime = "\(m)" + minutesMText
            }else{
                stringTime += " \(m)" + minutesMText
            }
        }
        if s != 0{
            if stringTime.isEmpty{
                stringTime = "\(s)" + secondsSText
            }else{
                stringTime += " \(s)" + secondsSText
            }
        }
        return stringTime
    }
    
}

extension focusCompletedVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            return arrAllAppsTabsData.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocsedCompletedItem"), owner: nil) as? tblCellFocsedCompletedItem {

            if let title = arrAllAppsTabsData[row][tabMatricsObject.keyFocusAppTitle] as? String{
                cell.lblTitleName.stringValue = title
                cell.lblTitleName.toolTip = title
            }else if let title = arrAllAppsTabsData[row][tabMatricsObject.keyFocusDomainTitle] as? String{
                cell.lblTitleName.stringValue = title
                cell.lblTitleName.toolTip = title
            }
            if let duration = arrAllAppsTabsData[row][tabMatricsObject.keyFocusDuration] as? Int{
                cell.lblDuration.stringValue = getStringTimeFromSeconds(seconds: duration)
                cell.progress.maxValue = Double(focusModeActualDurationPerformed)
                cell.progress.doubleValue = Double(duration)
            }
            
            
            return cell
        }
        
        return NSTableCellView()
    }

}
