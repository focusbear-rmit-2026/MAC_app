//
//  popUpBlockConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class popUpBlockConfirmVc: NSViewController {
    
    @IBOutlet weak var checkBoxMarkCurrentTaskAsCompleted: NSButton!
    @IBOutlet weak var btnInfoAlScore: hoverInfoButton!
    @IBOutlet weak var btnWorkingOnSomethingElse: Button!
    @IBOutlet weak var imgView: NSImageView!
    
    @IBOutlet weak var boxNoTaskSpecified: NSBox!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var comboBoxSelectTask: searchableComboBox!
    @IBOutlet weak var lblSelectTask: NSTextField!
    @IBOutlet weak var btnSetTask: Button!
    
    
    @IBOutlet weak var boxTimerIntention: NSBox!
    @IBOutlet weak var boxTimer: NSBox!
    @IBOutlet weak var btnCloseAskIntentionBox: cursorButton!
    @IBOutlet weak var btnInfoTemporaryAllow: hoverInfoButton!
    @IBOutlet weak var lblTitleAskIntention: NSTextField!
    @IBOutlet weak var lblBtnConfirmReportBadAi: NSTextField!
    @IBOutlet weak var lblBtnReportBadAi: NSTextField!
    @IBOutlet weak var btnConvinceAgain: underLineButton!
    @IBOutlet weak var boxBellIconIntentionBox: NSBox!
    @IBOutlet weak var btnBelIconIntentionBox: cursorButton!
    @IBOutlet weak var btnBelIcon: cursorButton!
    @IBOutlet weak var boxBellIcon: NSBox!
    @IBOutlet weak var popupButtonMinutes: NSPopUpButton!
    @IBOutlet weak var lblSelectMinutes: NSTextField!
    @IBOutlet weak var lblTimerIntentionBox: NSTextField!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnConvince: Button!
    @IBOutlet var textViewIntension: NSTextView!
    @IBOutlet weak var stackViewSetDurationToUse: NSStackView!
    @IBOutlet weak var lblSubTitleIntention: NSTextField!
    @IBOutlet weak var lblTitleIntention: NSTextField!
    @IBOutlet weak var boxAskIntention: NSBox!
    @IBOutlet weak var boxAllowDomain: NSBox!
    @IBOutlet weak var checkBoxAllowDomain: NSButton!
    @IBOutlet weak var lblCheckBoxAllowDomain: NSTextField!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var stackViewProgress: NSStackView!
    @IBOutlet weak var btnInfoProgress: hoverInfoButton!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var lblAi: NSTextField!
    @IBOutlet weak var lblIntention: NSTextField!
    @IBOutlet weak var btnEditSettings: Button!// not in use
    @IBOutlet weak var btnBlock: underLineButton!
    @IBOutlet weak var btnAllow: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnBlockAndAddToRelaxMode: Button!
    @IBOutlet weak var btnSeeMore: cursorButton!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var currentApp:NSRunningApplication?
    var currentAppName = ""
    var isAppBlocking = true
    var url:String = ""
    var fullUrl = ""
    var script:String = ""
    var browser:BROWSER?
    var titleText = "Do you need to use <URL> when you're focusing on <FOCUSTYPE>?"
    var intentionText = "Your intention was \"<INTENTION>\""
    var currentPid: pid_t?
    var lastBlockReasonFromAi = ""
    let maxProgressCount = 50
    var isAiWaiting = false
    var isBlockByAi:Bool = false
    
    var isUserTypingIntention = false
    var isUserTypingTime:Date?
    var isAskingConvinceAiIntention = false
    var isShowingUseDistractingUrlFlow = false
    var tabTitle:String?
    var currentRunningFocusModeName = ""
    var arrSeconds = [30, 60, 120, 300, 600]
    var scoreForThisSiteApp: Double?
    var domain = ""
    var payload:[String:Any]?
    var isFailedToGetResponse = false
    var isBrowser = false
    var aiReasonTrackingArea:NSTrackingArea?
    var convincedAiReasonTrackingArea:NSTrackingArea?
    
    var isItemCheckedByConvinceAi = false
    private var arrAllTasks = [NSDictionary]()
    private var lastTasksAPICallDate: Date?
    private let tasksCacheInterval: TimeInterval = 120 // 2 minutes
    var currentTaskInToDoPlayer:String?
    
    
    var titleChangedFocus = "Have you changed focus?"
    var changeTaskText = "Want to change your current task?"
    var suggestedTaskText = "It looks like you're now working on <TASK>."
    var buttoWorkingOnOldTask = "No I'm still working on <TASK>"
    var titleStillWorking = "Are you still working on \"<TASK>\" as part of your focus goal: \"<GOAL>\"?"
    var titleStillFocusGoal = "Is your focus goal still: \"<GOAL>\"?"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblSelectTask.stringValue = "No current task, select a task to proceed."
        btnWorkingOnSomethingElse.title = "No I'm working on something else now"
        btnSetTask.title = "Set Task"
        checkBoxMarkCurrentTaskAsCompleted.title = "Mark the previous task as complete"
        
        if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
            btnWorkingOnSomethingElse.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonWorkingSomethingElseText") as? String ?? btnWorkingOnSomethingElse.title
            btnSetTask.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonSetTask") as? String ?? btnSetTask.title
            lblSelectTask.stringValue = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleSelectTask") as? String ?? lblSelectTask.stringValue
            titleStillFocusGoal = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoal") as? String ?? titleStillFocusGoal
            titleStillWorking = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoalAndTask") as? String ?? titleStillWorking
        }
        
        btnConvinceAgain.title = "Let me convince the AI again"
        btnAllow.title = "Yes - just this time"
        btnBlock.title = "No - I was getting distracted"
        btnEditSettings.title = "Edit Settings"
        btnBlockAndAddToRelaxMode.title = "Block and save for Relax mode"
        btnBelIcon.toolTip = "Report bad AI blocking decision"
        btnBelIconIntentionBox.toolTip = "Report bad AI blocking decision"
        lblBtnReportBadAi.stringValue = "Report Bad AI decision"
        lblBtnConfirmReportBadAi.stringValue = "Report Bad AI decision"
        lblTitleAskIntention.stringValue = "What do you want to do while you're here?"
        if let reportBadAIResponseVcInfo = configjson.value(forKey: "reportBadAIResponseVcInfo") as? NSDictionary{
            btnBelIcon.toolTip = reportBadAIResponseVcInfo.value(forKey: "title") as? String ?? btnBelIcon.toolTip
        }
        btnBelIconIntentionBox.toolTip = btnBelIcon.toolTip
        
        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            titleText = popUpBlockConfirmVcInfo.value(forKey: "title") as? String ?? titleText
            btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
            btnBlock.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockText") as? String ?? btnBlock.title
            btnEditSettings.title = popUpBlockConfirmVcInfo.value(forKey: "buttonEditSettingsText") as? String ?? btnEditSettings.title
            intentionText = popUpBlockConfirmVcInfo.value(forKey: "intentionText") as? String ?? intentionText
            btnBlockAndAddToRelaxMode.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockAndAddToRelaxModeText") as? String ?? btnBlockAndAddToRelaxMode.title
            lblBtnReportBadAi.stringValue = popUpBlockConfirmVcInfo.value(forKey: "reportBadAiTooltip") as? String ?? lblBtnReportBadAi.stringValue
            lblTitleAskIntention.stringValue = popUpBlockConfirmVcInfo.value(forKey: "titleAskIntentionText") as? String ?? lblTitleAskIntention.stringValue
            btnConvinceAgain.title = popUpBlockConfirmVcInfo.value(forKey: "buttonConvinceAgain") as? String ?? btnConvinceAgain.title
            titleChangedFocus = popUpBlockConfirmVcInfo.value(forKey: "titleChangedFocus") as? String ?? titleChangedFocus
            changeTaskText = popUpBlockConfirmVcInfo.value(forKey: "changeTaskText") as? String ?? changeTaskText
            suggestedTaskText = popUpBlockConfirmVcInfo.value(forKey: "suggestedTaskText") as? String ?? suggestedTaskText
            buttoWorkingOnOldTask = popUpBlockConfirmVcInfo.value(forKey: "buttoWorkingOnOldTask") as? String ?? buttoWorkingOnOldTask
        }
        
        if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
            checkBoxMarkCurrentTaskAsCompleted.title = popUpAddNewFocusGoalVcInfo.value(forKey: "buttonMarkCurrentTaskAsCompleted") as? String ?? checkBoxMarkCurrentTaskAsCompleted.title
        }
        lblBtnConfirmReportBadAi.stringValue = lblBtnReportBadAi.stringValue
        lblTitle.stringValue = titleText
        
        btnAllow.isSecondaryButton = true
        btnEditSettings.isSecondaryButton = true
        stackViewProgress.isHidden = true
        
        popupButtonMinutes.removeAllItems()
        popupButtonMinutes.addItems(withTitles: ["30\(secondsSText)", "1\(minutesMText)", "2\(minutesMText)", "5\(minutesMText)", "10\(minutesMText)"])
        
        textViewIntension.delegate = self
        btnBelIcon.wantsLayer = true
        btnConvinceAgain.isHidden = true
        
        
        
        imgView.image = NSImage(named: "Glasses-Bear-250-px_V3")
        imgView.animates = true
        btnWorkingOnSomethingElse.isSecondaryButton = true
        comboBoxSelectTask.customDelegate = self
        comboBoxSelectTask.stringValue = ""
        comboBoxSelectTask.items.removeAll()
        arrAllTasks.removeAll()
        comboBoxSelectTask.reloadData()
        btnSetTask.isSecondaryButton = true
    }
    
    
    func updateTrackingAreaIfNeeded() {
        // Remove the old tracking area if it exists
        if let trackingArea = self.aiReasonTrackingArea {
            lblAi.removeTrackingArea(trackingArea)
        }
        
        if let trackingArea = self.convincedAiReasonTrackingArea {
            lblTitleIntention.removeTrackingArea(trackingArea)
        }
        
        // Recreate the tracking area with the updated bounds
        createTrackingArea()
    }
    
    func createTrackingArea(){
        if boxAskIntention.isHidden{
            aiReasonTrackingArea = NSTrackingArea.init(rect: lblAi.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
            lblAi.addTrackingArea(aiReasonTrackingArea!)
        }
        
        convincedAiReasonTrackingArea = NSTrackingArea.init(rect: lblTitleIntention.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        lblTitleIntention.addTrackingArea(convincedAiReasonTrackingArea!)
        
    }
    
    override func viewDidLayout() {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
            }
        }
    }
    func resetView(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool, browser:BROWSER?,currentPid: pid_t?, tabTitle:String?, fullUrl:String, aiBlockReason:String?, isTimeOut:Bool, isBlockByAi:Bool, scoreForThisSiteApp: Double?, payload:[String:Any]?, isBrowser:Bool, suggestedTask:String?, suggestedTaskId:String?){
        self.scoreForThisSiteApp = scoreForThisSiteApp
        if self.currentApp != nil{
            if self.currentApp == currentApp{
                return;
            }
        }
        
        boxNoTaskSpecified.isHidden = true
        btnWorkingOnSomethingElse.isHidden = true
        currentTaskInToDoPlayer = nil
        btnCloseAskIntentionBox.isHidden = true
        isItemCheckedByConvinceAi = false
        btnInfoTemporaryAllow.isHidden = true
        lblTitleAskIntention.isHidden = true
        btnConvinceAgain.isHidden = true
        self.isBrowser = isBrowser
        self.payload = nil
        checkBoxAllowDomain.state = .off
        isAiWaiting = false
        isAppBlocking = isBlockApp
        self.script = script
        self.url = url
        self.fullUrl = fullUrl
        currentRunningFocusModeName = ""
        self.browser = browser
        self.currentPid = currentPid
        lastBlockReasonFromAi = ""
        self.tabTitle = tabTitle
        boxAskIntention.isHidden = true
        isAskingConvinceAiIntention = false
        isShowingUseDistractingUrlFlow = false
        self.isBlockByAi = isBlockByAi
        if SettingsManagerObject.cuddlyModeProgressCount >= maxProgressCount{
            stackViewProgress.isHidden = true
        }else{
            stackViewProgress.isHidden = false
            lblProgress.stringValue = "\(SettingsManagerObject.cuddlyModeProgressCount) / \(maxProgressCount)"
            progressBar.doubleValue = Double(SettingsManagerObject.cuddlyModeProgressCount)
        }
        
        if isAnyAllowedFocusModeActivityRunning{
            if currentHabitPlaying != nil{
                currentRunningFocusModeName = currentHabitPlaying?.name ?? ""
            }else if currentActivityPlaying != nil{
                currentRunningFocusModeName = currentActivityPlaying?.name ?? ""
            }
        }else{
            currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
        }
        
        domain = ""
        convincedAiReason = ""
        if isAppBlocking{
            boxAllowDomain.isHidden = true
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: blockedAppName)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: currentRunningFocusModeName)
            if !whatToAchieveInFocusBlock.isEmpty{
                lblIntention.isHidden = false
                lblIntention.stringValue = intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
            }else{
                lblIntention.isHidden = true
            }
            
            if let currentTaskInToDoPlayer = getCurrentTaskInFocusMode(){
                addLog(text: "currentTaskInToDoPlayer:- \(currentTaskInToDoPlayer)")
                var currentTaskText = "Current task is \"<TASK>\""
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    currentTaskText = popUpBlockConfirmVcInfo.value(forKey: "currentTaskText") as? String ?? currentTaskText
                }
                currentTaskText = currentTaskText.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                if lblIntention.isHidden{
                    lblIntention.stringValue = currentTaskText
                    lblIntention.isHidden = false
                }else{
                    lblIntention.stringValue = lblIntention.stringValue + "\n\n" + currentTaskText
                }
                self.currentTaskInToDoPlayer = currentTaskInToDoPlayer
            }
            
            lblTitle.stringValue = blockTitle
            lblAi.isHidden = true
            btnBlockAndAddToRelaxMode.isHidden = true
            self.btnSeeMore.isHidden = true
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isBrowser{
                boxBellIcon.isHidden = false
                self.payload = payload
                lblFocusAlignmentScore.isHidden = false
                var focusAlignmentScoreText = ""
                if let score = scoreForThisSiteApp{
                    focusAlignmentScoreText = "AI relevance score for this app: <SCORE>%"
                    if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                        focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "aiRelevanceScoreAppText") as? String ?? focusAlignmentScoreText
                    }
                    let aiScore = (score*100).rounded()
                    focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(aiScore)")
                }else{
                    focusAlignmentScoreText = "Your Focus alignment score is <SCORE>%"
                    if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                        focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "focusAlignmentScoreText") as? String ?? focusAlignmentScoreText
                    }
                    focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(currentFocusAlignmentScore)")
                }
                lblFocusAlignmentScore.stringValue = focusAlignmentScoreText
            }else{
                boxBellIcon.isHidden = true
                lblFocusAlignmentScore.isHidden = true
            }
            
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isBrowser{
                boxBellIcon.isHidden = false
                lblAi.isHidden = false
                if let aiBlockReason = aiBlockReason{
                    isFailedToGetResponse = false
                    lastBlockReasonFromAi = aiBlockReason
                    self.lblAi.stringValue = cropText(aiBlockReason)
                    self.btnSeeMore.isHidden = false
                }else{
                    isFailedToGetResponse = true
                    boxBellIcon.isHidden = true
                    if isTimeOut{
                        isAiWaiting = true
                        var waitingAiText = "Waiting for AI decision..."
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            waitingAiText = popUpBlockConfirmVcInfo.value(forKey: "waitingAiText") as? String ?? waitingAiText
                        }
                        self.lblAi.stringValue = waitingAiText
                    }else{
                        var urlNotVerifiedText = "The status of this app could not be verified."
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            urlNotVerifiedText = popUpBlockConfirmVcInfo.value(forKey: "appNotVerifiedText") as? String ?? urlNotVerifiedText
                        }
                        self.lblAi.stringValue = urlNotVerifiedText
                    }
                    
                }
            }else{
                lblAi.isHidden = true
                boxBellIcon.isHidden = true
                self.btnSeeMore.isHidden = true
            }
            
            // new work v 2.28.451
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isBrowser{
                if let suggestedTask = suggestedTask{
                    lblTitle.stringValue = titleChangedFocus
                    lblIntention.stringValue = suggestedTaskText.replacingOccurrences(of: "<TASK>", with: suggestedTask)
                    lblSelectTask.stringValue = changeTaskText
                    
                    lblAi.isHidden = true
                    self.btnSeeMore.isHidden = true
                    btnAllow.isHidden = false
                    boxNoTaskSpecified.isHidden = false
                    btnWorkingOnSomethingElse.isHidden = true
                    lblIntention.isHidden = false
                    if let currentTaskInToDoPlayer = currentTaskInToDoPlayer{
                        btnAllow.title = buttoWorkingOnOldTask.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = false
                    }else if !whatToAchieveInFocusBlock.isEmpty{
                        btnAllow.title = buttoWorkingOnOldTask.replacingOccurrences(of: "<TASK>", with: whatToAchieveInFocusBlock)
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = true
                    }else{
                        btnAllow.title = "Yes"
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
                        }
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = true
                    }
                    
                }else{
                    if let currentTaskInToDoPlayer = currentTaskInToDoPlayer{
                        var title = titleStillWorking.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                        title = title.replacingOccurrences(of: "<GOAL>", with: whatToAchieveInFocusBlock)
                        lblTitle.stringValue = title
                        boxNoTaskSpecified.isHidden = true
                        btnAllow.isHidden = false
                    }else{
                        lblTitle.stringValue = titleStillFocusGoal.replacingOccurrences(of: "<GOAL>", with: whatToAchieveInFocusBlock)
                        boxNoTaskSpecified.isHidden = false
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = true
                        btnAllow.isHidden = true
                    }
                    lblIntention.isHidden = true
                    
                    lblAi.isHidden = true
                    btnWorkingOnSomethingElse.isHidden = false
                    btnAllow.title = "Yes and this app is relevant"
                    if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                        btnAllow.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonAppRelevantText") as? String ?? btnAllow.title
                    }
                }
                btnInfoAlScore.isHidden = false
                btnAllow.isSecondaryButton = false
            }else{
                boxNoTaskSpecified.isHidden = true
                btnAllow.title = "Yes"
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
                }
                btnInfoAlScore.isHidden = true
                btnAllow.isSecondaryButton = true
                btnAllow.isHidden = false
            }
            btnBlock.title = "Block this app"
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                btnBlock.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockAppText") as? String ?? btnBlock.title
            }
            
        }else{
            domain = getDomainFromUrl(url: fullUrl)
            boxAllowDomain.isHidden = true
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
                self.payload = payload
                lblFocusAlignmentScore.isHidden = false
                boxBellIcon.isHidden = false
                var focusAlignmentScoreText = ""
                
                
                if let score = scoreForThisSiteApp{
                    focusAlignmentScoreText = "AI relevance score for this site: <SCORE>%"
                    if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                        focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "aiRelevanceScoreText") as? String ?? focusAlignmentScoreText
                    }
                    let aiScore = (score*100).rounded()
                    focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(aiScore)")
                }else{
                    focusAlignmentScoreText = "Your Focus alignment score is <SCORE>%"
                    if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                        focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "focusAlignmentScoreText") as? String ?? focusAlignmentScoreText
                    }
                    focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(currentFocusAlignmentScore)")
                }
                
                lblFocusAlignmentScore.stringValue = focusAlignmentScoreText
            }else{
                boxBellIcon.isHidden = true
                lblFocusAlignmentScore.isHidden = true
            }
            
            btnBlockAndAddToRelaxMode.isHidden = true
            
            
            var urlString = url
            let maxUrlStringCount = 100
            if urlString.count > maxUrlStringCount{
                urlString = String(urlString.prefix(maxUrlStringCount)) + "..."
            }
            
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: urlString)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: currentRunningFocusModeName)
            
            if !whatToAchieveInFocusBlock.isEmpty{
                lblIntention.isHidden = false
                lblIntention.stringValue = self.intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
            }else{
                lblIntention.isHidden = true
            }
            
            lblTitle.stringValue = blockTitle
            
            if let currentTaskInToDoPlayer = getCurrentTaskInFocusMode(){
                addLog(text: "currentTaskInToDoPlayer:- \(currentTaskInToDoPlayer)")
                var currentTaskText = "Current task is \"<TASK>\""
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    currentTaskText = popUpBlockConfirmVcInfo.value(forKey: "currentTaskText") as? String ?? currentTaskText
                }
                currentTaskText = currentTaskText.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                if lblIntention.isHidden{
                    lblIntention.stringValue = currentTaskText
                    lblIntention.isHidden = false
                }else{
                    lblIntention.stringValue = lblIntention.stringValue + "\n\n" + currentTaskText
                }
                self.currentTaskInToDoPlayer = currentTaskInToDoPlayer
            }
            
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
                boxBellIcon.isHidden = false
                lblAi.isHidden = false
                self.btnSeeMore.isHidden = false
                if let aiBlockReason = aiBlockReason{
                    isFailedToGetResponse = false
                    lastBlockReasonFromAi = aiBlockReason
                    self.lblAi.stringValue = cropText(aiBlockReason)
                    self.btnSeeMore.isHidden = false
                }else{
                    isFailedToGetResponse = true
                    boxBellIcon.isHidden = true
                    if isTimeOut{
                        isAiWaiting = true
                        var waitingAiText = "Waiting for AI decision..."
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            waitingAiText = popUpBlockConfirmVcInfo.value(forKey: "waitingAiText") as? String ?? waitingAiText
                        }
                        self.lblAi.stringValue = waitingAiText
                    }else{
                        var urlNotVerifiedText = "The status of this url could not be verified."
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            urlNotVerifiedText = popUpBlockConfirmVcInfo.value(forKey: "urlNotVerifiedText") as? String ?? urlNotVerifiedText
                        }
                        self.lblAi.stringValue = urlNotVerifiedText
                    }
                    
                }
            }else{
                lblAi.isHidden = true
                boxBellIcon.isHidden = true
                self.btnSeeMore.isHidden = true
            }
            
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isBrowser{
                if let suggestedTask = suggestedTask{
                    lblTitle.stringValue = titleChangedFocus
                    lblIntention.stringValue = suggestedTaskText.replacingOccurrences(of: "<TASK>", with: suggestedTask)
                    lblSelectTask.stringValue = changeTaskText
                    
                    lblAi.isHidden = true
                    self.btnSeeMore.isHidden = true
                    btnAllow.isHidden = false
                    boxNoTaskSpecified.isHidden = false
                    btnWorkingOnSomethingElse.isHidden = true
                    lblIntention.isHidden = false
                    if let currentTaskInToDoPlayer = currentTaskInToDoPlayer{
                        btnAllow.title = buttoWorkingOnOldTask.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = false
                    }else if !whatToAchieveInFocusBlock.isEmpty{
                        btnAllow.title = buttoWorkingOnOldTask.replacingOccurrences(of: "<TASK>", with: whatToAchieveInFocusBlock)
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = true
                    }else{
                        btnAllow.title = "Yes"
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
                        }
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = true
                    }
                    
                }else{
                    lblSelectTask.stringValue = "No current task, select a task to proceed."
                    if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                        lblSelectTask.stringValue = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleSelectTask") as? String ?? lblSelectTask.stringValue
                    }
                    if let currentTaskInToDoPlayer = currentTaskInToDoPlayer{
                        var title = titleStillWorking.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                        title = title.replacingOccurrences(of: "<GOAL>", with: whatToAchieveInFocusBlock)
                        lblTitle.stringValue = title
                        boxNoTaskSpecified.isHidden = true
                        btnAllow.isHidden = false
                    }else{
                        lblTitle.stringValue = titleStillFocusGoal.replacingOccurrences(of: "<GOAL>", with: whatToAchieveInFocusBlock)
                        boxNoTaskSpecified.isHidden = false
                        checkBoxMarkCurrentTaskAsCompleted.isHidden = true
                        btnAllow.isHidden = true
                    }
                    lblIntention.isHidden = true
                    
                    lblAi.isHidden = true
                    btnWorkingOnSomethingElse.isHidden = false
                    btnAllow.title = "Yes and this site is relevant"
                    if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                        btnAllow.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonSiteRelevantText") as? String ?? btnAllow.title
                    }
                }
                btnInfoAlScore.isHidden = false
                btnAllow.isSecondaryButton = false
                
            }else{
                boxNoTaskSpecified.isHidden = true
                btnAllow.title = "Yes"
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
                }
                btnInfoAlScore.isHidden = true
                btnAllow.isSecondaryButton = true
                btnAllow.isHidden = false
            }
            btnBlock.title = "Block this site"
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                btnBlock.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockUrlText") as? String ?? btnBlock.title
            }
            
        }
        
        self.currentApp = currentApp
        currentAppName = blockedAppName
        updateTrackingAreaIfNeeded()
        startTimer()
        hidePopUpFocusGoalConfirmationView()
        hidePopUpAddNewFocusGoalView()
        hidePopUpSaveThisTaskForLaterView()
        
        if SettingsManagerObject.isAiCheckUrlEnabled{// check added 3.32.491
            if getCurrentTaskInFocusMode() == nil && whatToAchieveInFocusBlock.isEmpty{// added on 2/9/25 on version 2.27.409
                showoPopUpAddNewFocusGoalView()
                let pickTaskText =  "AI can’t tell if this fits your work. Pick a task to guide Focus Bear!"
                popUpAddNewFocusGoalVcObj?.lblTitle.stringValue = pickTaskText
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    popUpAddNewFocusGoalVcObj?.lblTitle.stringValue = popUpBlockConfirmVcInfo.value(forKey: "pickTaskText") as? String ?? pickTaskText
                }
            }
        }
        
        if boxNoTaskSpecified.isHidden == false{
            
            if let suggestedTask = suggestedTask{
                comboBoxSelectTask.stringValue = suggestedTask
            }else{
                comboBoxSelectTask.stringValue = ""
            }
            
            
            loadTasks()
        }
        checkBoxMarkCurrentTaskAsCompleted.state = .off
    }
    
    func loadTasks() {
        
        //  If API was called within last 2 minutes, use cached data
        if let lastCall = lastTasksAPICallDate,
           Date().timeIntervalSince(lastCall) < tasksCacheInterval,
           !arrAllTasks.isEmpty {
            
            print("✅ Using cached tasks")
            // Even with cached API tasks, always merge latest task-player tasks at top
            let cachedTodoIds = Set(arrCurrentFocusTasks.compactMap { $0["task_id"] as? String })
            let filteredCached = arrAllTasks.filter { task in
                guard let id = task.value(forKey: "id") as? String else { return true }
                return !cachedTodoIds.contains(id)
            }
            let todoAsDicts: [NSDictionary] = arrCurrentFocusTasks.map { task in
                ["title": task["task_name"] as? String ?? "",
                 "id": task["task_id"] as? String ?? ""] as NSDictionary
            }
            updateComboBox(with: todoAsDicts + filteredCached)
            return
        }
        
        print("🌐 Calling API")
        
        comboBoxSelectTask.isEnabled = false
        comboBoxSelectTask.items.removeAll()
        arrAllTasks.removeAll()
        loader.startAnimation(self)
        
        allApiObject.getAllTasks { json in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.comboBoxSelectTask.isEnabled = true
                self.loader.stopAnimation(self)
                
                guard let json = json else { return }
                
                // Remove completed tasks. added in v3.32.487
                let filteredTasks = json.filter { task in
                    let status = task.value(forKey: "status") as? String ?? ""
                    return status.uppercased() != "COMPLETED"
                }
                
                // Sort API tasks by updated_at (most recently worked on first)
                let sortedTasks = filteredTasks.sorted { t1, t2 in
                    let s1 = t1.value(forKey: "updated_at") as? String ?? ""
                    let s2 = t2.value(forKey: "updated_at") as? String ?? ""
                    
                    let d1 = getDateFromStringInUtc(dateString: s1) ?? .distantPast
                    let d2 = getDateFromStringInUtc(dateString: s2) ?? .distantPast
                    
                    return d1 > d2
                }
                
                self.arrAllTasks = sortedTasks
                self.lastTasksAPICallDate = Date() // ✅ save API call time
                
                // Merge task-player tasks at the top, deduplicated
                let todoPlayerIds = Set(arrCurrentFocusTasks.compactMap { $0["task_id"] as? String })
                let filteredApiTasks = sortedTasks.filter { task in
                    guard let id = task.value(forKey: "id") as? String else { return true }
                    return !todoPlayerIds.contains(id)
                }
                // Convert task-player tasks to NSDictionary to match the list type
                let todoAsDicts: [NSDictionary] = arrCurrentFocusTasks.map { task in
                    ["title": task["task_name"] as? String ?? "",
                     "id": task["task_id"] as? String ?? ""] as NSDictionary
                }
                let mergedTasks = todoAsDicts + filteredApiTasks
                
                self.updateComboBox(with: mergedTasks)
                
                
                
                func getDateFromStringInUtc(dateString: String) -> Date? {
                    let df = DateFormatter()
                    df.locale = Locale(identifier: "en_US_POSIX")
                    df.timeZone = TimeZone(secondsFromGMT: 0)
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" // matches your examples
                    return df.date(from: dateString)
                }
            }
        }
    }
    
    private func updateComboBox(with tasks: [NSDictionary]) {
        comboBoxSelectTask.items.removeAll()
        
        for task in tasks {
            let title = task.value(forKey: "title") as? String ?? ""
            comboBoxSelectTask.items.append(title)
            print(title)
        }
        
        comboBoxSelectTask.reloadData()
    }
    
    
    func cropText(_ text: String, limit: Int = 100) -> String {
        if text.count > limit {
            let index = text.index(text.startIndex, offsetBy: limit)
            return text[text.startIndex..<index] + "..."
        } else {
            return text
        }
    }
    
    func setAiReason(reason:String){
        
    }
    
    func hidePopUpFocusGoalConfirmationView(){
        if popUpFocusGoalConfirmationVcObj != nil{
            if self.view.subviews.contains(popUpFocusGoalConfirmationVcObj!.view){
                popUpFocusGoalConfirmationVcObj!.view.removeFromSuperview()
            }
        }
    }
    
    func hidePopUpAddNewFocusGoalView(){
        if popUpAddNewFocusGoalVcObj != nil{
            if self.view.subviews.contains(popUpAddNewFocusGoalVcObj!.view){
                popUpAddNewFocusGoalVcObj!.view.removeFromSuperview()
            }
        }
    }
    
    func hidePopUpSaveThisTaskForLaterView(){
        if popUpSaveThisTaskForLaterVcObj != nil{
            if self.view.subviews.contains(popUpSaveThisTaskForLaterVcObj!.view){
                popUpSaveThisTaskForLaterVcObj!.view.removeFromSuperview()
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("mouseEntered")
        if !boxAskIntention.isHidden{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    return;// aiReasonTrackingArea may get focus even after it's in below level
                }
            }
        }
        if event.trackingArea == aiReasonTrackingArea && boxAskIntention.isHidden{
            if boxAskIntention.isHidden == false{
                return;
            }
            if popUpFocusGoalConfirmationVcObj != nil{
                if self.view.subviews.contains(popUpFocusGoalConfirmationVcObj!.view){
                    return;
                }
            }
            if popUpAddNewFocusGoalVcObj != nil{
                if self.view.subviews.contains(popUpAddNewFocusGoalVcObj!.view){
                    return;
                }
            }
            if popUpSaveThisTaskForLaterVcObj != nil{
                if self.view.subviews.contains(popUpSaveThisTaskForLaterVcObj!.view){
                    return;
                }
            }
            showTooltip(sender: lblAi, msg: lastBlockReasonFromAi, preferredEdge: .minX, maxWidthVal: 250, autoCloseOnMouseExit: true)
        }else if event.trackingArea == convincedAiReasonTrackingArea{
            if !convincedAiReason.isEmpty{
                showTooltip(sender: lblTitleIntention, msg: convincedAiReason, preferredEdge: .minX, maxWidthVal: 250, autoCloseOnMouseExit: true)
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        print("mouseExited")
        if event.trackingArea == aiReasonTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == convincedAiReasonTrackingArea{
            closePopoverTooltipIfVisible()
        }
    }
    
    override func viewWillDisappear() {
        closePopoverTooltipIfVisible()
        hidePopUpFocusGoalConfirmationView()
        hidePopUpAddNewFocusGoalView()
        hidePopUpSaveThisTaskForLaterView()
    }
    
    var convincedAiReason = ""
    func showConvincedAiPopUpBox(allowedByConvinceAiAlready:Bool, reason:String){
        startTimer()
        btnCloseAskIntentionBox.isHidden = true
        isUserTypingIntention = true
        isUserTypingTime = Date()
        lblTitleAskIntention.isHidden = true
        btnInfoTemporaryAllow.isHidden = true
        convincedAiReason = ""
        if allowedByConvinceAiAlready{
            boxAskIntention.isHidden = false
            stackViewSetDurationToUse.isHidden = true
            lblSubTitleIntention.isHidden = false
            isAskingConvinceAiIntention = false
            btnConvince.isEnabled = true
            isShowingUseDistractingUrlFlow = false
            textViewIntension.enclosingScrollView?.isHidden = true
            boxBellIconIntentionBox.isHidden = false
            isItemCheckedByConvinceAi = allowedByConvinceAiAlready
            if isAppBlocking{
                addLog(text: "[user-action] popUpBlockConfirmVc:- AIStillThinksAppDistracting")
                var focusAlignmentScoreText = "AI relevance score for this app: <SCORE>%"
                var stillDistractingTitle = "AI still thinks this app is distracting"
                var stillDistractingDescription = "Focus Bear's AI still thinks <URL> isn't relevant for what you're trying to achieve. Are you sure you need it?"
                var distractingForCurrentTaskDescription = "Focus Bear's AI still thinks <URL> isn't relevant for your current task \"<TASK>\". Are you sure you need it?"
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    stillDistractingDescription = popUpBlockConfirmVcInfo.value(forKey: "stillDistractingDescription") as? String ?? stillDistractingDescription
                    focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "aiRelevanceScoreAppText") as? String ?? focusAlignmentScoreText
                    stillDistractingTitle = popUpBlockConfirmVcInfo.value(forKey: "appStillDistractingTitle") as? String ?? stillDistractingTitle
                    distractingForCurrentTaskDescription = popUpBlockConfirmVcInfo.value(forKey: "distractingForCurrentTaskDescription") as? String ?? distractingForCurrentTaskDescription
                }
                let score = scoreForThisSiteApp ?? 0
                let aiScore = (score*100).rounded()
                focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(aiScore)")
                
                if reason.isEmpty{
                    lblTitleIntention.stringValue = stillDistractingTitle + " \n\n" + focusAlignmentScoreText
                }else{
                    convincedAiReason = reason
                    lblTitleIntention.stringValue = stillDistractingTitle + " \n\n" + cropText(reason) + " \n\n" + focusAlignmentScoreText
                }
                
                
                if let currentTaskInToDoPlayer = getCurrentTaskInFocusMode(){
                    distractingForCurrentTaskDescription = distractingForCurrentTaskDescription.replacingOccurrences(of: "<URL>", with: self.currentAppName)
                    distractingForCurrentTaskDescription = distractingForCurrentTaskDescription.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                    lblSubTitleIntention.stringValue = distractingForCurrentTaskDescription
                }else{
                    stillDistractingDescription = stillDistractingDescription.replacingOccurrences(of: "<URL>", with: self.currentAppName)
                    lblSubTitleIntention.stringValue = stillDistractingDescription
                }
                
            }else{
                addLog(text: "[user-action] popUpBlockConfirmVc:- AIStillThinkSiteDistracting")
                var focusAlignmentScoreText = "AI relevance score for this site: <SCORE>%"
                var stillDistractingTitle = "AI still thinks this site is distracting"
                var stillDistractingDescription = "Focus Bear's AI still thinks <URL> isn't relevant for what you're trying to achieve. Are you sure you need it?"
                var distractingForCurrentTaskDescription = "Focus Bear's AI still thinks <URL> isn't relevant for your current task \"<TASK>\". Are you sure you need it?"
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "aiRelevanceScoreText") as? String ?? focusAlignmentScoreText
                    stillDistractingTitle = popUpBlockConfirmVcInfo.value(forKey: "stillDistractingTitle") as? String ?? stillDistractingTitle
                    stillDistractingDescription = popUpBlockConfirmVcInfo.value(forKey: "stillDistractingDescription") as? String ?? stillDistractingDescription
                    distractingForCurrentTaskDescription = popUpBlockConfirmVcInfo.value(forKey: "distractingForCurrentTaskDescription") as? String ?? distractingForCurrentTaskDescription
                }
                
                let score = scoreForThisSiteApp ?? 0
                let aiScore = (score*100).rounded()
                focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(aiScore)")
                
                if reason.isEmpty{
                    lblTitleIntention.stringValue = stillDistractingTitle + " \n\n" + focusAlignmentScoreText
                }else{
                    convincedAiReason = reason
                    lblTitleIntention.stringValue = stillDistractingTitle + " \n\n" + cropText(reason) + " \n\n" + focusAlignmentScoreText
                }
                
                var urlString = self.url
                let maxUrlStringCount = 100
                if urlString.count > maxUrlStringCount{
                    urlString = String(urlString.prefix(maxUrlStringCount)) + "..."
                }
                
                if let currentTaskInToDoPlayer = getCurrentTaskInFocusMode(){
                    distractingForCurrentTaskDescription = distractingForCurrentTaskDescription.replacingOccurrences(of: "<URL>", with: urlString)
                    distractingForCurrentTaskDescription = distractingForCurrentTaskDescription.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
                    lblSubTitleIntention.stringValue = distractingForCurrentTaskDescription
                }else{
                    stillDistractingDescription = stillDistractingDescription.replacingOccurrences(of: "<URL>", with: urlString)
                    lblSubTitleIntention.stringValue = stillDistractingDescription
                }
                
            }
            btnConvince.title = buttonYesText
            btnCancel.title = buttonNoText
            btnConvince.isSecondaryButton = false
            btnCancel.isSecondaryButton = true
            textViewIntension.string = ""
            textViewIntension.window?.makeFirstResponder(textViewIntension)
            btnConvinceAgain.isHidden = false
        }else{
            addLog(text: "[user-action] popUpBlockConfirmVc:- ConvinceAiwhyNecessary")
            convincedAiReason = ""
            boxAskIntention.isHidden = false
            stackViewSetDurationToUse.isHidden = true
            lblSubTitleIntention.isHidden = false
            isAskingConvinceAiIntention = true
            btnConvince.isEnabled = false
            isShowingUseDistractingUrlFlow = false
            textViewIntension.enclosingScrollView?.isHidden = false
            boxBellIconIntentionBox.isHidden = true
            lblTitleIntention.stringValue = "Convince the AI why it's necessary"
            lblSubTitleIntention.stringValue = "Give more info to the AI to explain why you need to use this site"
            btnConvince.title = "Convince the AI"
            if isAppBlocking{
                lblSubTitleIntention.stringValue = "Give more info to the AI to explain why you need to use this app"
            }
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                lblTitleIntention.stringValue = popUpBlockConfirmVcInfo.value(forKey: "convinceAiTitle") as? String ?? lblTitleIntention.stringValue
                lblSubTitleIntention.stringValue = popUpBlockConfirmVcInfo.value(forKey: "convinceAiDescription") as? String ?? lblSubTitleIntention.stringValue
                btnConvince.title = popUpBlockConfirmVcInfo.value(forKey: "buttonConvinceText") as? String ?? btnConvince.title
                if isAppBlocking{
                    lblSubTitleIntention.stringValue = popUpBlockConfirmVcInfo.value(forKey: "appConvinceAiDescription") as? String ?? lblSubTitleIntention.stringValue
                }
            }
            
            textViewIntension.string = ""
            textViewIntension.string = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["intentionForSite"] as? String ?? ""
            btnCancel.title = buttonCancelText
            btnConvince.isSecondaryButton = false
            btnCancel.isSecondaryButton = true
            
            
            textViewIntension.window?.makeFirstResponder(textViewIntension)
            btnConvinceAgain.isHidden = true
        }
    }
    
    
    
    var isSetIntentionFirstTime = false
    func showUseDistractingUrlFlow(isSetIntentionFirstTime:Bool){
        addLog(text: "[user-action] popUpBlockConfirmVc:- showUseDistractingUrlFlow")
        startTimer()
        self.isSetIntentionFirstTime = isSetIntentionFirstTime
        btnCloseAskIntentionBox.isHidden = false
        lblTitleAskIntention.isHidden = false
        boxAskIntention.isHidden = false
        stackViewSetDurationToUse.isHidden = false
        lblSubTitleIntention.isHidden = false
        isAskingConvinceAiIntention = false
        btnConvince.isEnabled = false
        isShowingUseDistractingUrlFlow = true
        textViewIntension.enclosingScrollView?.isHidden = false
        popupButtonMinutes.selectItem(at: 0)
        boxBellIconIntentionBox.isHidden = true
        btnInfoTemporaryAllow.isHidden = false
        if isAppBlocking && currentApp != nil{
            let appNameLowercased = currentAppName.lowercased()
            if isSetIntentionFirstTime{
                textViewIntension.string = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["convinceAiIntention"] as? String ?? ""
                lblSubTitleIntention.isHidden = true
            }else{
                textViewIntension.string = ""
                lblSubTitleIntention.isHidden = false
                
                let totalDurationSpent = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["totalDurationSpent"] as? Int ?? 0
                let time = getStringTimeFromSeconds(seconds:totalDurationSpent)
                var timeSpentText = "Total time spent: <TIME>"
                if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
                    timeSpentText = setIntentionBlockedUrlsVcInfo.value(forKey: "timeSpentText") as? String ?? timeSpentText
                }
                timeSpentText = timeSpentText.replacingOccurrences(of: "<TIME>", with: "\(time)")
                lblSubTitleIntention.stringValue = timeSpentText
            }
            btnCancel.title = "Block this app"
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                btnCancel.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockAppText") as? String ?? btnCancel.title
            }
        }else{
            if isSetIntentionFirstTime{
                textViewIntension.string = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["convinceAiIntention"] as? String ?? ""
                lblSubTitleIntention.isHidden = true
            }else{
                textViewIntension.string = ""
                lblSubTitleIntention.isHidden = false
                
                let totalDurationSpent = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["totalDurationSpent"] as? Int ?? 0
                let time = getStringTimeFromSeconds(seconds:totalDurationSpent)
                var timeSpentText = "Total time spent: <TIME>"
                if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
                    timeSpentText = setIntentionBlockedUrlsVcInfo.value(forKey: "timeSpentText") as? String ?? timeSpentText
                }
                timeSpentText = timeSpentText.replacingOccurrences(of: "<TIME>", with: "\(time)")
                lblSubTitleIntention.stringValue = timeSpentText
            }
            btnCancel.title = "Block this page"
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                btnCancel.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockUrlText") as? String ?? btnCancel.title
            }
            
        }
        lblSelectMinutes.stringValue = "How long do you need?"
        lblTitleIntention.stringValue = "Temporarily unlock"
        btnConvince.title = "Temporary access"
        convincedAiReason = ""
        
        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            lblTitleIntention.stringValue = popUpBlockConfirmVcInfo.value(forKey: "setIntentionText") as? String ?? lblTitleIntention.stringValue
            btnConvince.title = popUpBlockConfirmVcInfo.value(forKey: "buttonSetIntentionText") as? String ?? btnConvince.title
            lblSelectMinutes.stringValue = popUpBlockConfirmVcInfo.value(forKey: "titleSelectMinutesToUse") as? String ?? lblSelectMinutes.stringValue
        }
        
        
        btnConvince.isSecondaryButton = false
        btnCancel.isSecondaryButton = true
        textViewIntension.string = ""
        textViewIntension.window?.makeFirstResponder(textViewIntension)
        btnConvinceAgain.isHidden = true
    }
    
    
    func startTimer() {
        self.lblTimer.font = NSFont.monospacedDigitSystemFont(ofSize: self.lblTimer.font?.pointSize ?? 13, weight: .regular)
        self.lblTimerIntentionBox.font = NSFont.monospacedDigitSystemFont(ofSize: self.lblTimerIntentionBox.font?.pointSize ?? 13, weight: .regular)
        
        boxTimer.fillColor = NSColor.clear
        boxTimerIntention.fillColor = NSColor.clear
        lblTimer.textColor = .labelColor
        lblTimerIntentionBox.textColor = .labelColor
        
        lblTimer.isHidden = true
        lblTimerIntentionBox.isHidden = true
        
        currentTimer = 0
        var durationSeconds = 60

        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
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
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }
        self.lblTimerIntentionBox.stringValue = self.lblTimer.stringValue
        
        DispatchQueue.main.async {
            if self.timer != nil{
                self.timer?.invalidate()
                self.timer = nil
            }
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    func setProgres(){
        let remainingSeconds = self.totalDuration-currentTimer
        if remainingSeconds < 16{
            boxTimer.fillColor = NSColor(resource: .darkOrange)
            boxTimerIntention.fillColor = NSColor(resource: .darkOrange)
            lblTimer.textColor = .white
            lblTimerIntentionBox.textColor = .white
        }else if remainingSeconds < 31{
            lblTimer.isHidden = false
            lblTimerIntentionBox.isHidden = false
        }else{
            boxTimer.fillColor = NSColor.clear
            boxTimerIntention.fillColor = NSColor.clear
            lblTimer.textColor = .labelColor
            lblTimerIntentionBox.textColor = .labelColor
        }
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
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            self.lblTimerIntentionBox.stringValue = self.lblTimer.stringValue
            
            if let pid = self.currentPid{
                
                
                // Keep the blur over the real blocked Chrome window, not the front about:blank Meet
                // call window (see getGoogleChromeBlockingWindowBounds / showBlockConfirmWindow).
                let chromeTargetBounds = (self.browser == ._GOOGLE_CHROME_) ? getGoogleChromeBlockingWindowBounds() : nil
                let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
                let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
                let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]

                for info in windowInfoList! {
                    let windowPID = info["kCGWindowOwnerPID"] as! UInt32
                    if  windowPID == pid {
                        if let windowFrame = info["kCGWindowBounds"] as? NSDictionary{
                            let height = windowFrame.value(forKey: "Height") as? Int ?? 0
                            let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                            let x = windowFrame.value(forKey: "X") as? Int ?? 0
                            let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                            if let t = chromeTargetBounds, (abs(x - t.x) > 30 || abs(y - t.y) > 30) {
                                continue
                            }
                            if height > 250{
                                if self.view.window?.isVisible ?? false{
                                    var frame = NSRect(x: x, y: y, width: width, height: height)
                                    if self.browser != nil{
                                        frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: self.browser!)
                                    }
                                    showBlurWindow(frame: frame, browser: self.browser)
                                }else{
                                    if blurWcObj != nil{
                                        blurWcObj?.window?.close()
                                    }
                                }
                                break;
                            }
                            
                        }
                        
                    }
                }
            }
            
            if self.totalDuration <= self.currentTimer {
                addLog(text: "popUpBlockConfirmVc:- 30 seconds counter completed")
                self.timer?.invalidate()
                if let window = self.view.window{
                    if !window.isVisible{
                        blurWcObj?.window?.close()
                        addLog(text: "popUpBlockConfirmVc:- return:- window is not visible")
                        return;
                    }
                    self.view.window?.close()
                    blurWcObj?.window?.close()
                    if self.currentApp != nil && self.isAppBlocking{
                        focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false, isAppBlockByAi: self.isBlockByAi)
                        self.currentApp = nil
                    }else{
                        if SettingsManagerObject.isAIBlockingEnabled(){
                            focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: self.lastBlockReasonFromAi, browser: self.browser, isUrlBlockByAi: self.isBlockByAi, blockReason:"")
                        }else{
                            focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: nil, browser: self.browser, isUrlBlockByAi: self.isBlockByAi, blockReason:"")
                        }
                        
                    }
                }
            }
        }
    }
    
    @objc func performTimerCount() {
        if popUpFocusGoalConfirmationVcObj != nil{
            if self.view.subviews.contains(popUpFocusGoalConfirmationVcObj!.view){
                return;
            }
        }
        
        if popUpAddNewFocusGoalVcObj != nil{
            if self.view.subviews.contains(popUpAddNewFocusGoalVcObj!.view){
                return;
            }
        }
        
        if popUpSaveThisTaskForLaterVcObj != nil{
            if self.view.subviews.contains(popUpSaveThisTaskForLaterVcObj!.view){
                return;
            }
        }
        
        if isUserTypingIntention{
            if let isUserTypingTime = isUserTypingTime{
                let diffSeconds = Calendar.current.dateComponents([.second], from: isUserTypingTime, to: Date()).second ?? 0
                if diffSeconds > 2{
                    isUserTypingIntention = false
                }
            }
        }
        
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                let runningApp = NSWorkspace.shared.frontmostApplication
                if runningApp == self.currentApp{
                    if self.currentApp != nil{
                        exitFullScreen(runningApp:self.currentApp!)
                    }
                }
            }
        }
        
        if !isUserTypingIntention{
            currentTimer += 1
            setProgres()
        }
    }
    
    @IBAction func btnEditSettingClicked(_ sender: Any) {// not in use
    }
    
    
    @IBAction func btnBlockAppClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnBlockAppClicked")
        allApiObject.capturePosthog(event: "block-popup-no-i-was-getting-distracted-clicked", metadata: [:])
        if !SettingsManagerObject.isAiCheckUrlEnabled{
            blockClicked()
        }else{
            showPopUpSaveThisTaskForLaterView()
        }
    }
    
    func showPopUpFocusGoalConfirmationView(){
        addLog(text: "[user-action] popUpBlockConfirmVc:- showPopUpFocusGoalConfirmationView")
        self.view.addSubview(getPopUpFocusGoalConfirmationVcObject().view)
        self.view.addConstraints(subView: getPopUpFocusGoalConfirmationVcObject().view)
        let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
        getPopUpFocusGoalConfirmationVcObject().resetData(goal: whatToAchieveInFocusBlock, task: currentTaskInToDoPlayer, isApp: isAppBlocking)
    }
    
    func showoPopUpAddNewFocusGoalView(arrAllTasks:[NSDictionary]? = nil){
        addLog(text: "[user-action] popUpBlockConfirmVc:- showoPopUpAddNewFocusGoalView")
        self.view.addSubview(getPopUpAddNewFocusGoalVcObject().view)
        self.view.addConstraints(subView: getPopUpAddNewFocusGoalVcObject().view)
        let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
        getPopUpAddNewFocusGoalVcObject().resetData(intention: whatToAchieveInFocusBlock, task: currentTaskInToDoPlayer, arrAllTasksAdded: arrAllTasks)
    }
    
    func showPopUpSaveThisTaskForLaterView(){
        addLog(text: "[user-action] popUpBlockConfirmVc:- showPopUpSaveThisTaskForLaterView")
        self.view.addSubview(getPopUpSaveThisTaskForLaterVcObject().view)
        self.view.addConstraints(subView: getPopUpSaveThisTaskForLaterVcObject().view)
        var itemToShowasTask = ""
        if isAppBlocking{
            itemToShowasTask = self.currentAppName
        }else{
            itemToShowasTask = self.fullUrl
        }
        getPopUpSaveThisTaskForLaterVcObject().resetData(url: itemToShowasTask)
    }
    
    @IBAction func btnAllowAppClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnAllowAppClicked")
        
        if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isBrowser{
            
            showConvincedAiPopUpBox(allowedByConvinceAiAlready:false, reason: "")
            return;
        }
        
        
        if self.currentApp != nil && isAppBlocking{
            
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isFailedToGetResponse && !isBrowser{
                //                showConvincedAiPopUpBox(allowedByConvinceAiAlready:false, reason: "")
                //                isUserTypingIntention = true
                //                isUserTypingTime = Date()
                
                
                showPopUpFocusGoalConfirmationView()
                
                
            }else{
                arrAllowedAppsInCuddlyModeCurrentFocus.append(currentApp!)
                allApiObject.capturePosthog(event: "block-popup-yes-just-this-time-clicked", metadata: [:])
                if let browser = self.browser{
                    if let title = getActiveTabTitleOf(browser: browser)?.lowercased(){
                        arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(title)
                    }
                }
                
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                
                if stackViewProgress.isHidden == false{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                activateCurrentAppAgain()
            }
            
        }else{
            if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn() && !isFailedToGetResponse{
                //                showConvincedAiPopUpBox(allowedByConvinceAiAlready:false, reason: "")
                //                isUserTypingIntention = true
                //                isUserTypingTime = Date()
                showPopUpFocusGoalConfirmationView()
            }else{
                arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                if checkBoxAllowDomain.state == .on{
                    let domain = getDomainFromUrl(url: fullUrl).lowercased()
                    arrAllowedDomianInCuddlyModeCurrentFocus.append(domain)
                    allApiObject.capturePosthog(event: "allow-all-urls-from-domain-clicked", metadata: ["domain":domain])
                }
                
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                
                if stackViewProgress.isHidden == false{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                activateCurrentAppAgain()
            }
            
        }
        
    }
    
    func closeWindow(){
        self.currentApp = nil
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
    }
    
    func closeWindowNeedToCheckAppUrlAgain(){
        //        let gg = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]
        if isItemCheckedByConvinceAi{
            print("checked")
            // if convince ai is checked once then . check url from ai not call again because convince ai data locally stored in dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus and this prevent it to check url from ai again untill user convince ai again. so doing this to check it again from ai
            if isAppBlocking{
                let key = currentAppName.lowercased()
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus.removeValue(forKey: key)
            }else{
                let key = domain.lowercased()
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus.removeValue(forKey: domain)
            }
            
        }
        
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
        
        setFocusBearIconToNormal()
        focusModeCloseCurrentAppForAlignmentScore()
        habitBlockTimerHelper.stopUrlTimer()
        //        appdelegate!.timerAllowUrl?.invalidate()
        focusModeHelper.stopUrlTimer()
        currentBrowserUrlForAi = ""
    }
    
    @IBAction func btnInfoProgressClicked(_ sender: Any) {
        var messageText = "You're teaching Focus Bear what sites and apps are productive for you. It takes a bit of effort at first but within a few days, you'll have taught Focus Bear what apps and websites are productive."
        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            messageText = popUpBlockConfirmVcInfo.value(forKey: "progressInfoText") as? String ?? messageText
        }
        showTooltip(sender: btnInfoProgress, msg: messageText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    func blockClicked(){
        if self.currentApp != nil && isAppBlocking{
            focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false, isAppBlockByAi: self.isBlockByAi)
            self.currentApp = nil
        }else{
            if SettingsManagerObject.isAIBlockingEnabled(){
                focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: self.lastBlockReasonFromAi, browser: browser, isUrlBlockByAi: self.isBlockByAi, blockReason:"")
            }else{
                focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: self.isBlockByAi, blockReason:"")
            }
            
        }
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
        
        if stackViewProgress.isHidden == false{
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
            SettingsManagerObject.putUserLocalDeviceSettings()
        }
    }
    
    @IBAction func btnBlockAndAddToRelaxModeClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnBlockAndAddToRelaxModeClicked")
        allApiObject.capturePosthog(event: "save-distraction-for-later", metadata: [:])
        blockClicked()
        allApiObject.postSavedWebsite(url: fullUrl, completionHandler: {json in
            
        })
    }
    
    @IBAction func btnConvinceClicked(_ sender: Any) {
        if isAppBlocking && currentApp != nil{
            let appNameLowercased = currentAppName.lowercased()
            if isAskingConvinceAiIntention{
                let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                var currentHabitName:String?
                if isAnyAllowedFocusModeActivityRunning{
                    if currentHabitPlaying != nil{
                        currentHabitName = currentHabitPlaying?.name
                    }else if currentActivityPlaying != nil{
                        currentHabitName = currentActivityPlaying?.name
                    }
                }
                checkAppFromAiWithNewIntention(appName: currentAppName, intentionForThisApp: textViewIntension.string, currentRunningFocusModeName: currentRunningFocusModeName, shouldChangeCuddlyModeProgressCount: !stackViewProgress.isHidden, runningApp: currentApp!, currentHabitName: currentHabitName)
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                boxAskIntention.isHidden = true
                activateCurrentAppAgain()
                
            }else if !isShowingUseDistractingUrlFlow{
                showUseDistractingUrlFlow(isSetIntentionFirstTime: true)
            }else{
                // set intention work (use distracting site for duration work)
                let seconds = arrSeconds[popupButtonMinutes.indexOfSelectedItem]
                let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                var totalSeconds = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["totalDurationSpent"] as? Int ?? 0
                totalSeconds += seconds
                
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["totalDurationSpent"] = totalSeconds
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["userSetIntention"] = textViewIntension.string
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["endTime"] = endTime
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                boxAskIntention.isHidden = true
                
                if stackViewProgress.isHidden == false{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                activateCurrentAppAgain()
            }
        }else{
            if isAskingConvinceAiIntention{
                let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                var currentHabitName:String?
                if isAnyAllowedFocusModeActivityRunning{
                    if currentHabitPlaying != nil{
                        currentHabitName = currentHabitPlaying?.name
                    }else if currentActivityPlaying != nil{
                        currentHabitName = currentActivityPlaying?.name
                    }
                }
                checkUrlFromAiWithNewIntention(url: url, domain:domain, tab_title: tabTitle ?? "", intentionForThisSite: textViewIntension.string, currentRunningFocusModeName: currentRunningFocusModeName, shouldChangeCuddlyModeProgressCount: !stackViewProgress.isHidden, fullUrl:fullUrl, currentHabitName: currentHabitName)
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                boxAskIntention.isHidden = true
                activateCurrentAppAgain()
            }else if !isShowingUseDistractingUrlFlow{
                showUseDistractingUrlFlow(isSetIntentionFirstTime: true)
            }else{
                // set intention work (use distracting site for duration work)
                let seconds = arrSeconds[popupButtonMinutes.indexOfSelectedItem]
                let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                var totalSeconds = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["totalDurationSpent"] as? Int ?? 0
                totalSeconds += seconds
                
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["totalDurationSpent"] = totalSeconds
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["userSetIntention"] = textViewIntension.string
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["endTime"] = endTime
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                boxAskIntention.isHidden = true
                
                if stackViewProgress.isHidden == false{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                activateCurrentAppAgain()
            }
        }
    }
    
    func activateCurrentAppAgain(){
        DispatchQueue.global().async{
            DispatchQueue.main.async {
                NSApplication.shared.deactivate()
                if let lastApp = self.currentApp {
                    lastApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                }else if let lastApp = lastFrontMostApplication{
                    lastApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                }
            }
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "[user-action] btnCancelClicked")
        if isAskingConvinceAiIntention{
            boxAskIntention.isHidden = true
        }else{
            if !isShowingUseDistractingUrlFlow{
                allApiObject.capturePosthog(event: "block-no-clicked", metadata: [:])
                showPopUpSaveThisTaskForLaterView()
            }else{
                blockClicked()
            }
        }
    }
    
    @IBAction func popupButtonMinutesClicked(_ sender: Any) {
        
    }
    
    @IBAction func btnBellIconClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- ReportbadAIClicked")
        allApiObject.capturePosthog(event: "report-bad-ai-clicked", metadata: [:])
        
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
        
        setFocusBearIconToNormal()
        focusModeCloseCurrentAppForAlignmentScore()
        habitBlockTimerHelper.stopUrlTimer()
        //        appdelegate!.timerAllowUrl?.invalidate()
        focusModeHelper.stopUrlTimer()
        currentBrowserUrlForAi = ""

        // Reporting a bad AI decision means the AI was wrong to block this — allow the current app/site
        // for the rest of this focus session so it isn't re-blocked on the next check. Snapshot the item
        // now so it's still correct if this (singleton) popup is later reset for a different block while
        // the report window is open. The allow only runs if the user actually submits the report (see
        // reportBadAIResponseVc.btnReportIssueClicked). We deliberately allow ONLY this exact app/URL —
        // not the whole domain, and not the active tab title (the tab could have changed by submit time,
        // and a bad-AI report shouldn't broadly unblock beyond the reported item).
        let reportedApp = self.currentApp
        let reportedUrl = self.url
        let reportedIsApp = self.isAppBlocking && self.currentApp != nil
        let onReported: () -> Void = {
            if reportedIsApp, let app = reportedApp {
                if !arrAllowedAppsInCuddlyModeCurrentFocus.contains(app){
                    arrAllowedAppsInCuddlyModeCurrentFocus.append(app)
                }
            }else{
                arrAllowedUrlsInCuddlyModeCurrentFocus.append(reportedUrl)
            }
            addLog(text: "popUpBlockConfirmVc:- bad-AI report submitted — allowed current \(reportedIsApp ? "app" : "site") for this session")
        }

        if isAppBlocking && currentApp != nil{
            showReportBadAIResponseWindow(url: nil, app: currentAppName, payload: payload, onReported: onReported)
        }else{
            showReportBadAIResponseWindow(url: fullUrl, app: nil, payload: payload, onReported: onReported)
        }

    }
    
    @IBAction func btnConvinceAgainClicked(_ sender: Any) {
        //        showConvincedAiPopUpBox(allowedByConvinceAiAlready: false, reason: "")
        addLog(text: "[user-action] btnConvinceAgainClicked")
        showPopUpFocusGoalConfirmationView()
    }
    //intentionForSite
    
    @IBAction func btnInfoTemporaryAllowClicked(_ sender: Any) {
        var msg = "This site’s been flagged as a distraction 🧠❗You can unlock it for now — just know it’ll be logged as non-productive time in your report."
        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            msg = popUpBlockConfirmVcInfo.value(forKey: "infoTemporaryAllow") as? String ?? msg
        }
        showTooltip(sender: btnInfoTemporaryAllow, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnCloseAskIntentionBoxClicked(_ sender: Any) {
        addLog(text: "[user-action] btnCloseAskIntentionBoxClicked")
        btnCloseAskIntentionBox.isHidden = true
        showConvincedAiPopUpBox(allowedByConvinceAiAlready: true, reason: lastBlockReasonFromAi)
        //        if self.isSetIntentionFirstTime{
        //            showConvincedAiPopUpBox(allowedByConvinceAiAlready: true, reason: lastBlockReasonFromAi)
        //        }else{
        //            btnCancelClicked(self)
        //        }
    }
    
    @IBAction func btnSeeMoreClicked(_ sender: Any) {
        self.lblAi.stringValue = lastBlockReasonFromAi
        self.btnSeeMore.isHidden = true
    }
    
    @IBAction func btnSetTaskClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnSetTaskClicked")
        
        taskPlayerVcObj?.updateIntentionToPlayer()
        
        let taskName = comboBoxSelectTask.stringValue
        guard !taskName.isEmpty else { return }

        let shouldComplete = checkBoxMarkCurrentTaskAsCompleted.state == .on

        // If arrAllTasks is already populated (cache hit), deduplicate synchronously.
        // Otherwise fetch fresh tasks first to avoid a race condition where the async
        // load cleared arrAllTasks before the user tapped "Set Task" (#1679).
        let tasksToCheck = arrAllTasks
        if !tasksToCheck.isEmpty {
            addLog(text: "popUpBlockConfirmVc btnSetTaskClicked: using cached \(tasksToCheck.count) tasks for dedup")
            setTaskWithDeduplication(taskName: taskName, candidateTasks: tasksToCheck, shouldComplete: shouldComplete)
        } else {
            addLog(text: "popUpBlockConfirmVc btnSetTaskClicked: arrAllTasks empty – fetching fresh list for dedup")
            loader.startAnimation(self)
            allApiObject.getAllTasks { [weak self] freshTasks in
                guard let self = self else { return }
                let tasks = freshTasks ?? []
                DispatchQueue.main.async {
                    self.loader.stopAnimation(self)
                    self.arrAllTasks = tasks
                    self.setTaskWithDeduplication(taskName: taskName, candidateTasks: tasks, shouldComplete: shouldComplete)
                }
            }
        }
    }

    /// Creates a new task **or** reuses an existing one with the same name (case-insensitive).
    /// Extracted so both the cached and fresh-fetch paths share the same logic (#1679).
    private func setTaskWithDeduplication(taskName: String, candidateTasks: [NSDictionary], shouldComplete: Bool) {
        if let match = TaskDeduplicationHelper.existingTask(named: taskName, in: candidateTasks) {
            addLog(text: "popUpBlockConfirmVc: task '\(taskName)' already exists – reusing existing task, skipping creation.")
            closeWindow()
            if let id = match.task.value(forKey: "id") as? String,
               let taskTitle = match.task.value(forKey: "title") as? String {
                taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: shouldComplete)
            }
        } else {
            loader.startAnimation(self)
            let today = Date()
            let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
            let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            addLog(text: "Create new task:- name: \(taskName)")
            allApiObject.addTask(title: taskName, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result, json in
                if result {
                    addLog(text: "\(taskName) task created successfully.")
                }
                DispatchQueue.main.async { [self] in
                    loader.stopAnimation(self)
                    closeWindow()
                    if let json = json {
                        if let id = json.value(forKey: "id") as? String {
                            taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskName, id: id, duration: 600, shouldCompleteCurrentTask: shouldComplete)
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func btnWorkingOnSomethingElseClicked(_ sender: Any) {
        if arrAllTasks.count == 0{
            showoPopUpAddNewFocusGoalView()
        }else{
            showoPopUpAddNewFocusGoalView(arrAllTasks: arrAllTasks)
        }
    }
    
    @IBAction func btnInfoAlScoreClicked(_ sender: Any) {
        showTooltip(sender: btnInfoAlScore, msg: lastBlockReasonFromAi, preferredEdge: .minX, maxWidthVal: 250, autoCloseOnMouseExit: true)
    }
    
    @IBAction func checkBoxMarkCurrentTaskAsCompletedClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- checkBox mark current task as completed clicked.")
    }
    
//    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//        if commandSelector == #selector(NSResponder.insertTab(_:)) {
//            view.window?.selectNextKeyView(nil)
//            return true
//        }
//        
//        if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
//            view.window?.selectPreviousKeyView(nil)
//            return true
//        }
//        
//        return false
//    }
}

extension popUpBlockConfirmVc: NSTextViewDelegate{
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textViewIntension{
            if textView.string.count > 0{
                btnConvince.isEnabled = true
            }else{
                btnConvince.isEnabled = false
            }
            
            isUserTypingIntention = true
            isUserTypingTime = Date()
        }
    }
}

extension popUpBlockConfirmVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if comboBox.stringValue.isEmpty{
            return;
        }

    }
    func itemEditedByUser(comboBox: searchableComboBox) {
        isUserTypingIntention = true
        isUserTypingTime = Date()
    }
}
