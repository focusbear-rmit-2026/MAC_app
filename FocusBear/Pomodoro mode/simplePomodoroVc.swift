//
//  pomodoroVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.
import Cocoa

class simplePomodoroVc: NSViewController {
    
    
    @IBOutlet weak var boxFake: NSBox!
    @IBOutlet weak var btnStrictnessSuperStrict: cursorButton!
    @IBOutlet weak var btnStrictnessStrict: cursorButton!
    @IBOutlet weak var btnStrictnessNormal: cursorButton!
   
    @IBOutlet weak var comboBoxTask: searchableComboBox!
    @IBOutlet weak var btnInfoSelectFirstTask: hoverInfoButton!
    @IBOutlet weak var lblEnterFirstTask: NSTextField!
    @IBOutlet weak var stackViewFirstTask: NSStackView!
    @IBOutlet weak var boxBlankSpace: NSBox!
    @IBOutlet weak var stackViewStrictnessLevel: NSStackView!
    @IBOutlet weak var stackViewIntention: NSStackView!
    @IBOutlet weak var boxBlockingStyle: NSBox!
    @IBOutlet weak var boxBreakDuration: NSBox!
    @IBOutlet weak var imgViewAccordionMoreOptions: NSImageView!
    @IBOutlet weak var lblAccordionMoreOptions: NSTextField!
    @IBOutlet weak var boxAccordionMoreOptions: NSBox!
    
    @IBOutlet weak var lblSelectedStrictnessLevel: NSTextField!
    @IBOutlet weak var btnInfoWorkDuration: hoverInfoButton!
    @IBOutlet weak var btnInfoBreakDuration: hoverInfoButton!
    @IBOutlet weak var btnInfoIntention: hoverInfoButton!
    @IBOutlet weak var btnInfoStrictnessLevel: hoverInfoButton!
    
    @IBOutlet weak var btnPin: cursorButton!
    @IBOutlet weak var boxPin: NSBox!
    @IBOutlet weak var lblTipPermissions: NSTextField!
    @IBOutlet weak var boxTipPermissions: NSBox!
    @IBOutlet weak var btnError: Button!
    @IBOutlet weak var boxError: NSBox!
    @IBOutlet weak var lblStrictnessNormal: NSTextField!
    @IBOutlet weak var lblStrictnessStrict: NSTextField!
    @IBOutlet weak var lblStrictnessSuperStrict: NSTextField!
    @IBOutlet weak var lblTitleStrictnessLevel: NSTextField!
//    @IBOutlet weak var btnStrictnessNormal: hoverInfoButton!
//    @IBOutlet weak var btnStrictnessSuperStrict: hoverInfoButton!
//    @IBOutlet weak var btnStrictnessStrict: hoverInfoButton!
    @IBOutlet weak var sliderStrictness: CustomSlider!
    @IBOutlet weak var btnInfoAiBlocking: hoverInfoButton!
    @IBOutlet weak var boxTitle: NSBox!
    @IBOutlet weak var radioButtonBlockingStyleDistractingSites: NSButton!
    @IBOutlet weak var radioButtonBlockingStyleAi: NSButton!
    @IBOutlet weak var lblTitleBlockingStyle: NSTextField!
    @IBOutlet weak var topSpaceLblTitle: NSLayoutConstraint!
    @IBOutlet weak var heightBtnLetsDoIt: NSLayoutConstraint!
    @IBOutlet weak var lblTimerUnfocused: NSTextField!
    @IBOutlet weak var lblMinutesBreakDuration: NSTextField!
    @IBOutlet weak var lblMinutesWorkDuration: NSTextField!
    @IBOutlet weak var textFieldBreakDuration: NSTextField!
    @IBOutlet weak var textFieldWorkDuration: NSTextField!
    @IBOutlet weak var lblTitleBreakDuration: NSTextField!
    @IBOutlet weak var lblTitleWorkDuration: NSTextField!
    
 
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet var textViewAchieve: NSTextView!


    @IBOutlet weak var btnInfoPomodoro: cursorButton!
    
    var intentionToShowAgain = ""
    let workRatio = 5
    let breakRatio = 1
    var isBreakDurationComesFromBreakRatio = false
    var questionSecondText = "Which focus mode do you want to use?"
    var chooseTheFocusModeText = "Choose the focus mode and duration - you won't be able to change the focus mode until the time is up (you still get to use any app/website during the 5 minutes break)"
    
    var workDurationEmptyErrorText = "Work Duration can not be empty."
    var workDurationZeroErrorText = "Work Duration can not be 0."
    var breakDurationEmptyErrorText = "Break Duration can not be empty."
    var breakDurationZeroErrorText = "Break Duration can not be 0."
    
    var timerText = "Time spend unfocused: <TIME>"
//    var isFirstTime = false
    
   
    var popoverTooltip:NSPopover?// = NSPopover()
    
    var pomodoroTooltipVcObj:pomodoroTooltipVc?
    var alertExtendPostpone: NSAlert?
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc // only for cutOffTime in hardskip
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    var arrTourMessages: [[String : String]] = []
    var currentTourIndex = 0
    var isIntentionFromMorningPostpone = false
    let popoverMenuTour = NSPopover()
    var menuTourPopoverVcObj: menuTourPopoverVc?
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
    
    var arrAllTasks = [NSDictionary]()
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        arrTourMessages.removeAll()
        lblEnterFirstTask.stringValue = "What do you want to work on first?"
        lblAccordionMoreOptions.stringValue = "Focus Settings"
        
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        lblStrictnessNormal.stringValue = "Normal"
        lblStrictnessStrict.stringValue = "Strict"
        lblStrictnessSuperStrict.stringValue = "Super strict"
        
        lblTitleBlockingStyle.stringValue = "Blocking Style:"
        radioButtonBlockingStyleAi.title = "AI powered blocking (recommended)"
        radioButtonBlockingStyleDistractingSites.title = "Just block super distracting sites"
        
        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"


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
                lblTitleStrictnessLevel.stringValue = startingFocusModeInfo.value(forKey: "titleStrictnessLevel") as? String ?? lblTitleStrictnessLevel.stringValue
            }
        }
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
        }
        
        
        lblTitle.stringValue = "Pomodoro time!"
        var questionFirstText = "What do you want to achieve in this focus session?"
        btnLetsDoIt.title = "Let's do it"

        
        var tourSelectTasks = "Select tasks"
        var descriptionSelectTasks = "Choose tasks to focus on from Focus Bear's inbuilt to do list"
        var tourIntention = "Freeform intention"
        var descriptionIntention = "If you don't want to bother creating tasks, you can write a quick intention for what you'll do during this focus session"
        
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            if let title = pomodoroInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let questionFirst = pomodoroInfo.value(forKey: "questionFirstText") as? String{
                questionFirstText = questionFirst
            }
            if let questionSecondText = pomodoroInfo.value(forKey: "questionSecondText") as? String{
                self.questionSecondText = questionSecondText
            }
            if let buttonLetsDoItText = pomodoroInfo.value(forKey: "buttonLetsDoItText") as? String{
                btnLetsDoIt.title = buttonLetsDoItText
            }
            
            if let chooseTheFocusModeText = pomodoroInfo.value(forKey: "chooseTheFocusModeText") as? String{
                self.chooseTheFocusModeText = chooseTheFocusModeText
            }
            timerText = pomodoroInfo.value(forKey: "timerText") as? String ?? timerText

            
            tourSelectTasks = pomodoroInfo.value(forKey: "tourSelectTasks") as? String ?? tourSelectTasks
            descriptionSelectTasks = pomodoroInfo.value(forKey: "descriptionSelectTasks") as? String ?? descriptionSelectTasks
            tourIntention = pomodoroInfo.value(forKey: "tourIntention") as? String ?? tourIntention
            descriptionIntention = pomodoroInfo.value(forKey: "descriptionIntention") as? String ?? descriptionIntention
            lblTitleBlockingStyle.stringValue = pomodoroInfo.value(forKey: "titleBlockingStyleText") as? String ?? lblTitleBlockingStyle.stringValue
            radioButtonBlockingStyleAi.title = pomodoroInfo.value(forKey: "buttonBlockingStyleAiText") as? String ?? radioButtonBlockingStyleAi.title
            radioButtonBlockingStyleDistractingSites.title = pomodoroInfo.value(forKey: "buttonBlockingStyleDistractingSitesText") as? String ?? radioButtonBlockingStyleDistractingSites.title
            lblTitleWorkDuration.stringValue = pomodoroInfo.value(forKey: "pomodoroModeDurationText") as? String ?? lblTitleWorkDuration.stringValue
        }
        lblQuestionFirst.stringValue = questionFirstText
        
        var titleTour =  "Start Focus Session"
        var titlePomodoroTime = "Focus Time"
        var subTitlePomodoroTime = "You do 25 minutes of work (could be shorter or longer) and then have a 5 minute break. Click on the (i) to learn more about how it works."
        var titleBlockingStyle = "Blocking style"
        var subTitleBlockingStyle = "If you enable AI powered blocking, Focus Bear will use AI to check whether each website is relevant for what you’re trying to achieve in this focus session. It’s privacy safe - your identity is not shared with the AI."
        var titleWorkDuration = "Pomodoro mode duration"
        var subTitleWorkDuration = "Put in how long you want to focus for"
        var titleBreakDuration = "Break duration"
        var subTitleBreakDuration = "How long will you have as a break once you finish focusing"
        var titleIntention = "Intention"
        var subTitleIntention = "Put in what you hope to achieve during this focus session. Helps avoid getting distracted because you’re clear what your goals are."
        var titleStrictnessLevel = "Strictness level"
        var subTitleStrictnessLevel = "Adjust the slider to increase the strictness of your Focus session."
        
        
        
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            titleTour = simplePomodoroVcInfo.value(forKey: "titleTour") as? String ?? titleTour
            titlePomodoroTime = simplePomodoroVcInfo.value(forKey: "titlePomodoroTime") as? String ?? titlePomodoroTime
            subTitlePomodoroTime = simplePomodoroVcInfo.value(forKey: "subTitlePomodoroTime") as? String ?? subTitlePomodoroTime
            titleBlockingStyle = simplePomodoroVcInfo.value(forKey: "titleBlockingStyle") as? String ?? titleBlockingStyle
            subTitleBlockingStyle = simplePomodoroVcInfo.value(forKey: "subTitleBlockingStyle") as? String ?? subTitleBlockingStyle
            titleWorkDuration = simplePomodoroVcInfo.value(forKey: "titleWorkDuration") as? String ?? titleWorkDuration
            subTitleWorkDuration = simplePomodoroVcInfo.value(forKey: "subTitleWorkDuration") as? String ?? subTitleWorkDuration
            titleBreakDuration = simplePomodoroVcInfo.value(forKey: "titleBreakDuration") as? String ?? titleBreakDuration
            subTitleBreakDuration = simplePomodoroVcInfo.value(forKey: "subTitleBreakDuration") as? String ?? subTitleBreakDuration
            titleIntention = simplePomodoroVcInfo.value(forKey: "titleIntention") as? String ?? titleIntention
            subTitleIntention = simplePomodoroVcInfo.value(forKey: "subTitleIntention") as? String ?? subTitleIntention
            titleStrictnessLevel = simplePomodoroVcInfo.value(forKey: "titleStrictnessLevel") as? String ?? titleStrictnessLevel
            subTitleStrictnessLevel = simplePomodoroVcInfo.value(forKey: "subTitleStrictnessLevel") as? String ?? subTitleStrictnessLevel
            
            
            
            titleNormalMode = simplePomodoroVcInfo.value(forKey: "titleNormalMode") as? String ?? titleNormalMode
            descriptionNormalMode = simplePomodoroVcInfo.value(forKey: "descriptionNormalMode") as? String ?? descriptionNormalMode
            toolTipNormalMode = simplePomodoroVcInfo.value(forKey: "toolTipNormalMode") as? String ?? toolTipNormalMode
            titleStrictMode = simplePomodoroVcInfo.value(forKey: "titleStrictMode") as? String ?? titleStrictMode
            descriptionStrictMode = simplePomodoroVcInfo.value(forKey: "descriptionStrictMode") as? String ?? descriptionStrictMode
            toolTipStrictMode = simplePomodoroVcInfo.value(forKey: "toolTipStrictMode") as? String ?? toolTipStrictMode
            titleSuperStrictMode = simplePomodoroVcInfo.value(forKey: "titleSuperStrictMode") as? String ?? titleSuperStrictMode
            descriptionSuperStrictMode = simplePomodoroVcInfo.value(forKey: "descriptionSuperStrictMode") as? String ?? descriptionSuperStrictMode
            toolTipSuperStrictMode = simplePomodoroVcInfo.value(forKey: "toolTipSuperStrictMode") as? String ?? toolTipSuperStrictMode
            lblEnterFirstTask.stringValue = simplePomodoroVcInfo.value(forKey: "enterFirstTask") as? String ?? lblEnterFirstTask.stringValue
            
            lblAccordionMoreOptions.stringValue = simplePomodoroVcInfo.value(forKey: "focusSettingsText") as? String ?? lblAccordionMoreOptions.stringValue
        }
        lblStrictnessNormal.stringValue = "🟢 " + titleNormalMode
        lblStrictnessStrict.stringValue = "🟡 " + titleStrictMode
        lblStrictnessSuperStrict.stringValue = "🔴 " + titleSuperStrictMode
        
        arrTourMessages = [
            ["title": titlePomodoroTime, "description": subTitlePomodoroTime],
            ["title": titleBlockingStyle, "description": subTitleBlockingStyle],
            ["title": titleWorkDuration, "description": subTitleWorkDuration],
            ["title": titleBreakDuration, "description": subTitleBreakDuration],
            ["title": titleIntention, "description": subTitleIntention],
            ["title": titleStrictnessLevel, "description": subTitleStrictnessLevel]
        ]
        
        
        for i in 0..<arrTourMessages.count{
            if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }
//        if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroTourShown) == nil{Onboarding feedback 1st April #1341 remove tour
//            menuTourPopoverVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuTourPopoverVc")) as? menuTourPopoverVc
//            popoverMenuTour.contentViewController = menuTourPopoverVcObj
//            popoverMenuTour.animates = false
//            popoverMenuTour.behavior = .applicationDefined
//            currentTourIndex = 0
//            menuTourPopoverVcObj?.delegate = self
//            menuTourPopoverVcObj?.loadView()
//            menuTourPopoverVcObj?.lblMainTitle.stringValue = titleTour
//        }

        textViewAchieve.delegate = self

        btnError.title = "Fix it"
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            btnError.title = simplePomodoroVcInfo.value(forKey: "buttonFixItText") as? String ?? btnError.title
        }
        btnError.isSecondaryButton = true
        viewDidResize()
        
        boxError.isHidden = true
        boxTipPermissions.isHidden = true
        pinButtonTrackingArea = NSTrackingArea.init(rect: btnPin.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnPin.addTrackingArea(pinButtonTrackingArea!)
        
        btnInfoAiBlocking.isAutoClickEnabled = false
//        btnStrictnessNormal.isAutoClickEnabled = false
//        btnStrictnessSuperStrict.isAutoClickEnabled = false
//        btnStrictnessStrict.isAutoClickEnabled = false
        btnInfoWorkDuration.isAutoClickEnabled = false
        btnInfoBreakDuration.isAutoClickEnabled = false
        btnInfoIntention.isAutoClickEnabled = false
        btnInfoStrictnessLevel.isAutoClickEnabled = false
        btnInfoSelectFirstTask.isAutoClickEnabled = false
        
//        stackViewFirstTask.isHidden = true
        stackViewStrictnessLevel.isHidden = true
        stackViewIntention.isHidden = true
        boxBlockingStyle.isHidden = true
        boxBreakDuration.isHidden = true
        boxFake.isHidden = true
        boxBlankSpace.isHidden = false
        imgViewAccordionMoreOptions.image = NSImage(named: NSImage.goForwardTemplateName)
        
        comboBoxTask.customDelegate = self
        comboBoxTask.stringValue = ""
        
        comboBoxTask.items.removeAll()
        arrAllTasks.removeAll()
        comboBoxTask.reloadData()
    }
    
    var browserPermissionGiven = false
    override func viewDidAppear() {

        boxPin.isHidden = true
        if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroTourShown) == nil{//Onboarding feedback 1st April #1341 remove tour
            UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroTourShown)
            boxError.isHidden = true
            browserPermissionGiven = true
        }else{
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
        }
        
        btnLetsDoIt.isEnabled = true
        if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            if currentFocusModeStrictness == ._SUPER_STRICT_{
                for index in 0..<customBlockingScheduleManagerObj.arrBlockingSchedule.count{
                    if customBlockingScheduleManagerObj.arrBlockingSchedule[index].state == .on{
                        btnLetsDoIt.isEnabled = false
                        showMessageBoxFor(sender: btnLetsDoIt)
                        break;
                    }
                }
            }
        }
        isViewVisible = true
    }
    
    var messageBoxView: NSView?
    var hideWorkItem: DispatchWorkItem?
    
    func showMessageBoxFor(sender: NSView) {
        guard
            let window = sender.window,
            let contentView = window.contentView
        else { return }

        // Cancel previous timer
        hideWorkItem?.cancel()
        hideWorkItem = nil

        // Remove existing box
        messageBoxView?.removeFromSuperview()

        let vc = getMessageBoxVcObject()
        if !vc.isViewLoaded{
            vc.loadView()
        }
        var title = "Super Strict blocking schedule is active. You can’t start a focus session now."
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            title = common.value(forKey: "strictBlockingCannotChangeMessage") as? String ?? title
        }
        
        vc.resetView(title: title)
        vc.lblTitle.font = getRegularFont(size: 14)
        let boxView = vc.view
        messageBoxView = boxView

        // 🔁 Convert sender bounds → window contentView
        let senderRectInContent =
            sender.convert(sender.bounds, to: contentView)

        let boxSize = boxView.frame.size

        let x = senderRectInContent.maxX + 5
        let y = senderRectInContent.midY - boxSize.height / 2

        boxView.frame = NSRect(
            x: x,
            y: y,
            width: 220,
            height: 85
        )

        boxView.alphaValue = 1
        contentView.addSubview(boxView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: sender.window
        )
        
        // ⏱ Auto hide after 10 seconds
        let workItem = DispatchWorkItem { [weak self, weak boxView] in
            guard let view = boxView else { return }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                view.animator().alphaValue = 0
            }, completionHandler: {
                view.removeFromSuperview()
                self?.messageBoxView = nil
                if let self = self{
                    NotificationCenter.default.removeObserver(
                        self,
                        name: NSWindow.didResizeNotification,
                        object: sender.window
                    )
                }
            })
        }

        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 7, execute: workItem)
    }
    
    @objc func windowDidResize() {
        if let messageBoxView = messageBoxView{
            guard
                let window = btnLetsDoIt.window,
                let contentView = window.contentView
            else { return }
            
            let senderRectInContent =
            btnLetsDoIt.convert(btnLetsDoIt.bounds, to: contentView)

            let boxSize = messageBoxView.frame.size

            let x = senderRectInContent.maxX + 5
            let y = senderRectInContent.midY - boxSize.height / 2
            
            messageBoxView.frame = NSRect(
                x: x,
                y: y,
                width: messageBoxView.frame.width,
                height: messageBoxView.frame.height
            )
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
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    func updateBreakDuration(){
        let workDuration = textFieldWorkDuration.integerValue
        
        var breakDuration =  Int((Double(workDuration) / Double(5)) * Double(breakRatio))
        if breakDuration < 1{
            breakDuration = 1
        }
        textFieldBreakDuration.stringValue = "\(breakDuration)"
        isBreakDurationComesFromBreakRatio = true
        print("isBreakDurationComesFromBreakRatio true")
    }
    
    var focusModeKey = "isDefault"
    func loadLastIntentionOfFocusMode(){
        textViewAchieve.string = ""
        
        if radioButtonBlockingStyleAi.state == .on{
            focusModeKey = "isDeepWorkFocus"
        }else{
            focusModeKey = "isDefault"
        }
        for i in 0..<arrFocusType.count{
            if let isDeepWorkFocus = arrFocusType[i][focusModeKey] as? Bool{//this key will only be awailable in default focus type
                if  isDeepWorkFocus{
                    let lastIntentionUsed = arrFocusType[i]["lastIntentionUsed"] as? String ?? ""
                    textViewAchieve.string = lastIntentionUsed
                    break;
                }
            }
        }
//        if textViewAchieve.string.isEmpty{
//            btnLetsDoIt.isEnabled = false
//        }else{
//            btnLetsDoIt.isEnabled = true
//        }
    }
    
    override func viewWillAppear() {
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
        showSelectedStrictnessLevel()
        
        if isExpired{
            radioButtonBlockingStyleAi.state = .off
            radioButtonBlockingStyleDistractingSites.state = .on
        }else{
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsSimplePomodoroAiBlockingSelected) as? Bool{
                if state{
                    radioButtonBlockingStyleAi.state = .on
                    radioButtonBlockingStyleDistractingSites.state = .off
                }else{
                    radioButtonBlockingStyleAi.state = .off
                    radioButtonBlockingStyleDistractingSites.state = .on
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsSimplePomodoroAiBlockingSelected)
                radioButtonBlockingStyleAi.state = .on
                radioButtonBlockingStyleDistractingSites.state = .off
            }
        }
        loadLastIntentionOfFocusMode()
        
    
        lblTimerUnfocused.isHidden = false
        startTimer()
        textFieldWorkDuration.isEnabled = true
        textFieldBreakDuration.isEnabled = true
        btnLetsDoIt.isEnabled = true
        
        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
            textFieldWorkDuration.stringValue = "\(duration)"
        }
        updateBreakDuration()
        

        self.view.window?.styleMask.insert(.closable)
        
        viewDidResize()
        if !nextFocusSessionIntention.isEmpty{
            textViewAchieve.string = nextFocusSessionIntention
        }
        comboBoxTask.isEnabled = false
        comboBoxTask.stringValue = ""
        comboBoxTask.items.removeAll()
        arrAllTasks.removeAll()
        allApiObject.getAllTasks(completionHandler: {json in
            DispatchQueue.main.async { [self] in
                if let json = json{
                    
                    // Remove completed tasks. added in v3.32.487
                    let filteredTasks = json.filter { task in
                        let status = task.value(forKey: "status") as? String ?? ""
                        return status.uppercased() != "COMPLETED"
                    }
                    
                    let sortedTasks = filteredTasks.sorted { t1, t2 in
                        let s1 = t1.value(forKey: "created_at") as? String ?? ""
                        let s2 = t2.value(forKey: "created_at") as? String ?? ""
                        
                        let d1 = getDateFromStringInUtc(dateString: s1) ?? Date.distantPast
                        let d2 = getDateFromStringInUtc(dateString: s2) ?? Date.distantPast
                        
                        return d1 > d2
                    }
                    arrAllTasks = sortedTasks
                    for task in arrAllTasks{
                        let title = task.value(forKey: "title") as? String ?? ""
                        comboBoxTask.items.append(title)
                        print(title)
                    }
                    comboBoxTask.reloadData()
                    comboBoxTask.isEnabled = true
                    func getDateFromStringInUtc(dateString: String) -> Date? {
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "en_US_POSIX")
                        df.timeZone = TimeZone(secondsFromGMT: 0)
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" // matches your examples
                        return df.date(from: dateString)
                    }
                }
            }
        })
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

    @objc func viewDidResize(){
        print("viewDidResize")
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        if screenFrame.height < 600{ // 900 change to 600 v 2.27.435
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
                topSpaceLblTitle.constant = 10
            }else{
                heightBtnLetsDoIt.constant = 34
                topSpaceLblTitle.constant = 20
            }
            lblTitle.font = getRegularFont(size: fontSizeNinteen)

            lblQuestionFirst.font = getRegularFont(size: fontSizeTwelve)

            lblTitleWorkDuration.font =  getRegularFont(size: 15)
            lblTitleBreakDuration.font =  getRegularFont(size: fontSizeTwelve)
            lblMinutesWorkDuration.font =  getRegularFont(size: 15)
            lblMinutesBreakDuration.font =  getRegularFont(size: fontSizeTwelve)
            textFieldWorkDuration.font =  getRegularFont(size: 14)
            textFieldBreakDuration.font =  getRegularFont(size: fontSizeEleven)


            lblTimerUnfocused.font =  getRegularFont(size: fontSizeTwelve)
            btnLetsDoIt.font =  getRegularFont(size: fontSizeSixteen)

        }else{
            lblTitle.font =  getRegularFont(size: 25)
            lblQuestionFirst.font =  getRegularFont(size: 14)
            lblTitleWorkDuration.font =  getRegularFont(size: 20)
            lblTitleBreakDuration.font =  getRegularFont(size: 14)
            lblMinutesWorkDuration.font =  getRegularFont(size: 20)
            lblMinutesBreakDuration.font =  getRegularFont(size: 14)
            textFieldWorkDuration.font =  getRegularFont(size: 19)
            textFieldBreakDuration.font =  getRegularFont(size: 13)

            lblTimerUnfocused.font =  getRegularFont(size: 14)
            btnLetsDoIt.font =  getRegularFont(size: 20)
   
            heightBtnLetsDoIt.constant = 40
            topSpaceLblTitle.constant = 35
        }
    }
    
    
    @IBAction func radioButtonBlockingStyleAiClicked(_ sender: Any) {
        addLog(text:"[user-action] simplePomodoroVc:- radioButtonBlockingStyleAiClicked")
        if isExpired{
            radioButtonBlockingStyleAi.state = .off
            var titleNoAiBlocking = "AI blocking is only supported in Pro edition."
            if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
                titleNoAiBlocking = upgradeToProNagVcInfo.value(forKey: "titleNoAiBlocking") as? String ?? titleNoAiBlocking
            }
            showUpgradeToProNagWindow(titleText: titleNoAiBlocking, reason: "activate_ai_blocking_focus_session")
            return;
        }
        radioButtonBlockingStyleDistractingSites.state = .off
        loadLastIntentionOfFocusMode()
    }
    
    
    @IBAction func radioButtonBlockingStyleDistractingSitesClicked(_ sender: Any) {
        radioButtonBlockingStyleAi.state = .off
        loadLastIntentionOfFocusMode()
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
        
        if radioButtonBlockingStyleAi.state == .on{
            if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
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
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsManageTaskFirstTime) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsManageTaskFirstTime)
       
            addLog(text:"show alert UseToDoList first time from simple pomodoro view")
            
            var titleUseToDoList = "Do you want to use Focus Bear for your to do list for this focus session?"
            var buttonTryItText = "Try it out"
            var buttonNoThanksText = "No thanks"
            var titleEnableToDoListFuture = "If you want to try it out in the future, enable the To Do player setting under Preferences - Settings - To Do List"
            
            if let toDoPlayerVcInfo = configjson.value(forKey: "toDoPlayerVcInfo") as? NSDictionary{
                titleUseToDoList = toDoPlayerVcInfo.value(forKey: "titleUseToDoList") as? String ?? titleUseToDoList
                buttonTryItText = toDoPlayerVcInfo.value(forKey: "buttonTryItText") as? String ?? buttonTryItText
                buttonNoThanksText = toDoPlayerVcInfo.value(forKey: "buttonNoThanksText") as? String ?? buttonNoThanksText
                titleEnableToDoListFuture = toDoPlayerVcInfo.value(forKey: "titleEnableToDoListFuture") as? String ?? titleEnableToDoListFuture
            }

            
            let alertUseToDoList = NSAlert()
            alertUseToDoList.setSharingType()
            alertUseToDoList.messageText = titleUseToDoList
            alertUseToDoList.informativeText = titleEnableToDoListFuture
            alertUseToDoList.addButton(withTitle: buttonTryItText)
            alertUseToDoList.addButton(withTitle: buttonNoThanksText)
            
            alertUseToDoList.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if modalResponse == .alertFirstButtonReturn{
                    if !SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                        SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = true
                        SettingsManagerObject.isSettingsChanged = true
                        SettingsManagerObject.putUserLocalDeviceSettings()
                    }
                    self.btnLetsDoItClicked(self)
                }else{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    self.btnLetsDoItClicked(self)
                }
            })
            return;
        }

        if textFieldWorkDuration.isEnabled{
            currentPomodoroWorkDuration = textFieldWorkDuration.integerValue
        }
        if textFieldBreakDuration.isEnabled{
            currentPomodoroBreakDuration = textFieldBreakDuration.integerValue
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
                                    getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                    self.pomodoroModeStarted()
                                }else if currentState == ._POSTPON_EVENING_HABIT_{
                                    if SettingsManagerObject.isEasySkipEnabled{
                                        getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        self.pomodoroModeStarted()
                                    }else{
                                        var shouldAskPasswordForEvening = false
                                        if shouldAskPassword() && cutOffTime != nil && SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                            if isCutOffTimeGoing(){
                                                shouldAskPasswordForEvening = true
                                            }
                                        }
                                        
                                        if shouldAskPasswordForEvening{
                                            self.presentAsSheet(self.enterPasswordVcObj!)
                                            self.enterPasswordVcObj?.parentVc = self
                                            return;
                                        }else{
                                            getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                            self.pomodoroModeStarted()
                                        }
                                    }
                                }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
                                    getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                                    self.pomodoroModeStarted()
                                }
                            }else if modalResponse == .alertSecondButtonReturn{
                                self.pomodoroModeStarted()
                            }
                            if currentState != ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
                                
                                self.view.window?.close()//  will not work if view has changed (task player is viisble now). because if main view is changes then window is nil.no need to change anything
                            }else{
                                leftMenuVcObj?.showBreaksView()
                            }
                            allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
                        })
                        return;
                    }
                }
            }
        }
        nextFocusSessionIntention = ""
        pomodoroModeStarted()
        if currentState != ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438
            
            self.view.window?.close()//  will not work if view has changed (task player is viisble now). because if main view is changes then window is nil.no need to change anything
        }else{
            leftMenuVcObj?.showBreaksView()
        }
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }
    
    
    func pomodoroModeStarted(){
        addLog(text: "pomodoro mode Started")
        isFocusModeStartedAutomatically = false
        if arrFocusTypeForPomodoro.count == 0{
            return
        }
        if sliderStrictness.integerValue == 1{
            currentFocusModeStrictness = ._NORMAL_
            addLog(text: "focus mode is normal mode")
        }else if sliderStrictness.integerValue == 2{
            currentFocusModeStrictness = ._STRICT_
            addLog(text: "focus mode is strict mode")
        }else if sliderStrictness.integerValue == 3{
            currentFocusModeStrictness = ._SUPER_STRICT_
            addLog(text: "focus mode is super strict mode")
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

        if radioButtonBlockingStyleAi.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsSimplePomodoroAiBlockingSelected)
            SettingsManagerObject.isAiCheckUrlEnabled = true
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsSimplePomodoroAiBlockingSelected)
            SettingsManagerObject.isAiCheckUrlEnabled = false
        }
        
        minFocusAlignmentScoreToShowDistractingPopUp = 99.9
        if SettingsManagerObject.isDataCollectionModeEnabled{
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }
        for i in 0..<arrFocusType.count{
            if let isDeepWorkFocus = arrFocusType[i][focusModeKey] as? Bool{//this key will only be awailable in default focus type
                if  isDeepWorkFocus{
                    arrFocusType[i]["isOn"] = true
                    arrFocusType[i]["lastStartedDate"] = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")//
                    arrFocusType[i]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                    shouldReloadTaskPlayer = true
                    let focusModeId = arrFocusType[i]["id"] as? String ?? ""
                    let focusModeName = arrFocusType[i]["name"] as? String ?? ""
                    addLog(text: "Focus mode name is:- \(focusModeName)")// added v 3.31.474
                    addLog(text: "Focus mode id is:- \(focusModeId)")// added v 3.31.474
                    
                    if isAccessibilityEnabled(isPrompt: true){
                        enableDND()
                    }
                    workBeforeFocusBegin(index: i)
                    if !textViewAchieve.string.isEmpty{
                        arrFocusType[i]["lastIntentionUsed"] = textViewAchieve.string
                    }else{
                        arrFocusType[i]["lastIntentionUsed"] = ""
                    }
                    focusModeTaskString = arrFocusType[i]["lastTaskUsed"] as? String ?? ""
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    updateAllFocusModes()
                    taskCreatedByBlockPopup = ""
                    appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusType[i]["color"] as? String ?? "")
                    break;
                }
            }
            
        }
        
        
        isFocusModeRunning = true
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
        //focusButtonService
        focusButtonServiceObject.startFocusSession(seconds: minute*60)
        
        isFocusModeStartedFromPomodoroMode = true
    
        isSkipBreakActivityDuringPomodoro = true
        addLog(text: "SkipBreakActivityDuringPomodoro is true in simple focus session.")
        whatToAchieveInFocusBlock = textViewAchieve.string
        appdelegate!.focusModeStartted(isStartedByPusher: false)

        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled && currentState != ._MICRO_BREAK_{
            if !comboBoxTask.stringValue.isEmpty{
                taskPlayerVcObj?.taskToLoadForFirstTime = comboBoxTask.stringValue
                taskPlayerVcObj?.arrAllTasks = arrAllTasks
            }
            showTaskPlayerWindow(totalDuration: minute, intention: textViewAchieve.string, automatically:true)
        }else{
            if !getTaskPlayerVcObject().isViewLoaded{
                getTaskPlayerVcObject().loadView()
            }
            if !comboBoxTask.stringValue.isEmpty{
                taskPlayerVcObj?.taskToLoadForFirstTime = comboBoxTask.stringValue
                taskPlayerVcObj?.arrAllTasks = arrAllTasks
            }
            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: textViewAchieve.string)
            shouldReloadTaskPlayer = false
        }

        allApiObject.capturePosthog(event: "start-focus-session-manually", metadata: ["type":"simple-focus", "focusDuration":currentPomodoroWorkDuration, "breakDuration":currentPomodoroBreakDuration])
    }

    
    func passwordIsCorrect(){
        print("password Correct")
        isHardCorePomodoroModeOn = false
        self.view.window?.close()
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }
    
    override func viewWillDisappear() {
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
        isViewVisible = false
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



    @IBAction func btnInfoAiBlockingClicked(_ sender: Any) {
        var toolTipAiBlocking = "When you open a website you haven't specifically blocked or allowed, we'll use AI to check whether the website is relevant or not based on your focus intention. In strict mode, it will block it immediately if it's not relevant. In non strict mode, it will show a popup asking whether you really need it."
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            toolTipAiBlocking = simplePomodoroVcInfo.value(forKey: "toolTipAiBlocking") as? String ?? toolTipAiBlocking
        }
        
        showTooltip(sender: btnInfoAiBlocking, msg: toolTipAiBlocking, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    @IBAction func btnInfoPomodoroClicked(_ sender: Any) {
        if popoverTooltip == nil{
            popoverTooltip = NSPopover()
            popoverTooltip!.behavior = .transient
            popoverTooltip!.animates = false
            //        popoverTooltip!.delegate = appdelegate
        }
        if popoverTooltip!.isShown{
            popoverTooltip?.close()
        }
        let vc = getPomodoroTooltipVcObject()

        func getPomodoroTooltipVcObject()->pomodoroTooltipVc{
            if pomodoroTooltipVcObj == nil{
                pomodoroTooltipVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroTooltipVc")) as? pomodoroTooltipVc
            }
            return pomodoroTooltipVcObj!
        }
        popoverTooltip!.contentViewController = vc
        popoverTooltip!.contentSize = vc.view.frame.size
        
        popoverTooltip!.show(relativeTo: btnInfoPomodoro.bounds, of: btnInfoPomodoro, preferredEdge: NSRectEdge.maxX)
    }
    
    
//    @IBAction func btnStrictnessNormalClicked(_ sender: Any) {
//        var msg = "can pause/stop focus session at any time"
//        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                msg = startingFocusModeInfo.value(forKey: "strictnessNormalTooltip") as? String ?? msg
//            }
//        }
//        
//        showTooltip(sender: btnStrictnessNormal, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//    }
    
//    @IBAction func btnStrictnessStrictClicked(_ sender: Any) {
//        var msg = "requires countdown timer before pausing/stopping focus session"
//        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                msg = startingFocusModeInfo.value(forKey: "strictnessStrictTooltip") as? String ?? msg
//            }
//        }
//        
//        showTooltip(sender: btnStrictnessStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//    }

//    @IBAction func btnStrictnessSuperStrictClicked(_ sender: Any) {
//        var msg = "immediately block urls + prevents pausing/stopping focus session or opening settings"
//        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                msg = startingFocusModeInfo.value(forKey: "strictnessSuperStrictTooltip") as? String ?? msg
//            }
//        }
//        
//        showTooltip(sender: btnStrictnessSuperStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//    }
    
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
                    showExplainingPermissionsWindow(showingFromPomodoro: true)
                    self.intentionToShowAgain = self.textViewAchieve.string
                }
                
            })
        }else if !browserPermissionGiven{
            showExplainingPermissionsWindow(showingFromPomodoro: true)
            self.intentionToShowAgain = self.textViewAchieve.string
            self.view.window?.close()
        }
    }
    
    @IBAction func sliderStrictnessClicked(_ sender: Any) {
        if sliderStrictness.integerValue == 3{
            var strictnessSuperStrictClickedText = "I understand I cannot stop this focus session. I am committed to avoiding distractions and getting a ton of work done."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                    strictnessSuperStrictClickedText = startingFocusModeInfo.value(forKey: "strictnessSuperStrictClickedNewText") as? String ?? strictnessSuperStrictClickedText
                }
            }
            
            showTooltip(sender: sliderStrictness, msg: strictnessSuperStrictClickedText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
        showSelectedStrictnessLevel()
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

    @IBAction func btnInfoWorkDurationClicked(_ sender: Any) {
        showTooltip(sender: btnInfoWorkDuration, msg: arrTourMessages[2]["description"] ?? "", preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnInfoBreakDurationClicked(_ sender: Any) {
        showTooltip(sender: btnInfoBreakDuration, msg: arrTourMessages[3]["description"] ?? "", preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnInfoIntentionClicked(_ sender: Any) {
        showTooltip(sender: btnInfoIntention, msg: arrTourMessages[4]["description"] ?? "", preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
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
    
    @IBAction func btnViewAccordionMoreOptionsClicked(_ sender: Any) {
        if stackViewStrictnessLevel.isHidden{
            stackViewStrictnessLevel.isHidden = false
            stackViewIntention.isHidden = false
            boxBlockingStyle.isHidden = false
            boxBreakDuration.isHidden = false
            boxFake.isHidden = false
            imgViewAccordionMoreOptions.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
            boxBlankSpace.isHidden = true
           // stackViewFirstTask.isHidden = false
        }else{
            stackViewStrictnessLevel.isHidden = true
            stackViewIntention.isHidden = true
            boxBlockingStyle.isHidden = true
            boxBreakDuration.isHidden = true
            boxFake.isHidden = true
            imgViewAccordionMoreOptions.image = NSImage(named: NSImage.goForwardTemplateName)
            boxBlankSpace.isHidden = false
            if let window = self.view.window {
                if window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
         //   stackViewFirstTask.isHidden = true
        }
    }
    
    @IBAction func btnInfoSelectFirstTaskClicked(_ sender: Any) {
        var toolTipFirstTask = "Add the first task you’ll work on in this focus session. Starting with a clear task helps you stay on track."
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            toolTipFirstTask = simplePomodoroVcInfo.value(forKey: "toolTipFirstTask") as? String ?? toolTipFirstTask
        }
        showTooltip(sender: btnInfoSelectFirstTask, msg: toolTipFirstTask, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnStrictnessNormalClicked(_ sender: Any) {
        sliderStrictness.integerValue = 1
        sliderStrictnessClicked(self)
    }
    
    @IBAction func btnStrictnessStrictClicked(_ sender: Any) {
        sliderStrictness.integerValue = 2
        sliderStrictnessClicked(self)
    }
    
    @IBAction func btnStrictnessSuperStrictClicked(_ sender: Any) {
        sliderStrictness.integerValue = 3
        sliderStrictnessClicked(self)
    }
    
}

extension simplePomodoroVc: NSTextFieldDelegate, NSTextViewDelegate{
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
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == textViewAchieve{
//            if textView.string.isEmpty{
//                btnLetsDoIt.isEnabled = false
//            }else{
//                btnLetsDoIt.isEnabled = true
//            }
        }
    }
}

extension simplePomodoroVc: TourDelegate{
    func buttonNextClicked() {
        currentTourIndex += 1
        if currentTourIndex == 1{
            popoverMenuTour.show(relativeTo: lblTitleBlockingStyle.bounds, of: lblTitleBlockingStyle, preferredEdge: NSRectEdge.minX)
        }else if currentTourIndex == 2{
            popoverMenuTour.show(relativeTo: lblTitleWorkDuration.bounds, of: lblTitleWorkDuration, preferredEdge: NSRectEdge.minX)
        }else if currentTourIndex == 3{
            popoverMenuTour.show(relativeTo: lblTitleBreakDuration.bounds, of: lblTitleBreakDuration, preferredEdge: NSRectEdge.minX)
        }else if currentTourIndex == 4{
            popoverMenuTour.show(relativeTo: lblQuestionFirst.bounds, of: lblQuestionFirst, preferredEdge: NSRectEdge.minX)
        }else if currentTourIndex == 5{
            popoverMenuTour.show(relativeTo: lblTitleStrictnessLevel.bounds, of: lblTitleStrictnessLevel, preferredEdge: NSRectEdge.minX)
        }
        if currentTourIndex < arrTourMessages.count{
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentTourIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentTourIndex]["title"] ?? "", description: arrTourMessages[currentTourIndex]["description"] ?? "", buttonTitle: arrTourMessages[currentTourIndex]["buttonTitle"] ?? "", indexText: currentIndexText, arrList: [], progress: currentTourIndex + 1, progressMaxValue: arrTourMessages.count)
        }else{
            popoverMenuTour.close()
        }
    }
    func buttonCloseClicked() {
        popoverMenuTour.close()
    }
}

// scrollview added on 2/9/25 on version 2.27.409

extension simplePomodoroVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if comboBox.stringValue.isEmpty{
            return;
        }

    }
}
