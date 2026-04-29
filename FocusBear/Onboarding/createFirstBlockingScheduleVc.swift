//
//  createFirstBlockingScheduleVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 28/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class createFirstBlockingScheduleVc: NSViewController {
    
    
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var btnAddBlock: Button!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var lblSelectedStrictnessLevel: NSTextField!
    @IBOutlet weak var btnInfoStrictnessLevel: hoverInfoButton!
    @IBOutlet weak var lblTitleStrictnessLevel: NSTextField!
    @IBOutlet weak var lblStrictnessNormal: NSTextField!
    @IBOutlet weak var lblStrictnessStrict: NSTextField!
    @IBOutlet weak var lblStrictnessSuperStrict: NSTextField!
    @IBOutlet weak var sliderStrictness: CustomSlider!
    
    @IBOutlet weak var btnInfoIUseAi: hoverInfoButton!
    @IBOutlet weak var btnInfoSkipMicroBreaks: hoverInfoButton!
    @IBOutlet weak var checkBoxAiEnabled: NSButton!
    @IBOutlet weak var checkBoxSkipMicroBreaks: NSButton!
   
    
    @IBOutlet weak var scrollView: NSScrollView!

    @IBOutlet weak var datePickerTill: NSDatePicker!
    @IBOutlet weak var datePickerFrom: NSDatePicker!
    @IBOutlet weak var lblTitleTillTime: NSTextField!
    @IBOutlet weak var lblTitleFromTime: NSTextField!
    @IBOutlet weak var boxSunday: toggleTitledBox!
    @IBOutlet weak var boxSaturday: toggleTitledBox!
    @IBOutlet weak var boxFriday: toggleTitledBox!
    @IBOutlet weak var boxThursday: toggleTitledBox!
    @IBOutlet weak var boxWednesday: toggleTitledBox!
    @IBOutlet weak var boxTuesday: toggleTitledBox!
    @IBOutlet weak var boxMonday: toggleTitledBox!
    @IBOutlet weak var lblTitleScheduleDays: NSTextField!
    @IBOutlet weak var textFieldScheduleName: NSTextField!
    @IBOutlet weak var lblTitleScheduleName: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
  
    
    
    var blockMode:FOCUSMODESTRICTNESS = ._NORMAL_
    var arrAllWeekDayBox = [toggleTitledBox]()
    var focusModeDefaultIndex = 0
    var arrFocusTypeForBlockingSchedule = [[String : Any]]()
    
    var titleNormalMode = "Chill Mode"
    var descriptionNormalMode = "Stop focusing anytime, no questions asked."
    var toolTipNormalMode = "Best for gentle focus days. No barriers to pausing or stopping a session."
    var titleStrictMode = "Wait for it…"
    var descriptionStrictMode = "15-second delay before you can stop"
    var toolTipStrictMode = "Adds a 15s countdown before you can pause/stop. Great for catching impulsive decisions."
    var titleSuperStrictMode = "Iron Focus"
    var descriptionSuperStrictMode = "Once you start, you can't stop"
    var toolTipSuperStrictMode = "Once you start, there’s no backing out. Best for deep, distraction-free sessions."
  
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        lblTitle.stringValue = "Set Block Details"
        btnAddBlock.title = "Add Block"
        
        lblTitleScheduleName.stringValue = "Block name"
        lblTitleScheduleDays.stringValue = "Blocking schedule"
        lblTitleFromTime.stringValue = "From"
        lblTitleTillTime.stringValue = "Till"
        checkBoxSkipMicroBreaks.title = "Skip microbreaks"
        checkBoxAiEnabled.title = "Use Al to decide if websites should be allowed"
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        
        if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
            lblTitleScheduleName.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleScheduleName") as? String ?? lblTitleScheduleName.stringValue
            lblTitleScheduleDays.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleBlockingSchedule") as? String ?? lblTitleScheduleDays.stringValue
            lblTitleFromTime.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleFromTime") as? String ?? lblTitleFromTime.stringValue
            lblTitleTillTime.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleTillTime") as? String ?? lblTitleTillTime.stringValue
            checkBoxSkipMicroBreaks.title = blockingScheduleEditorVcInfo.value(forKey: "buttonSkipMicrobreaks") as? String ?? checkBoxSkipMicroBreaks.title
            checkBoxAiEnabled.title = blockingScheduleEditorVcInfo.value(forKey: "buttonEnableAi") as? String ?? checkBoxAiEnabled.title
        }
        
        if let info = configjson.value(forKey: "createFirstBlockingScheduleVcInfo") as? NSDictionary{
            lblTitle.stringValue = info.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnAddBlock.title = info.value(forKey: "buttonAddBlock") as? String ?? btnAddBlock.title
        }
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                lblTitleStrictnessLevel.stringValue = startingFocusModeInfo.value(forKey: "titleStrictnessLevel") as? String ?? lblTitleStrictnessLevel.stringValue
            }
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

        boxSunday.titleLabel.stringValue = "Sun"// todo need to  covert with some one
        boxSaturday.titleLabel.stringValue = "Sat"
        boxFriday.titleLabel.stringValue = "Fri"
        boxThursday.titleLabel.stringValue = "Thu"
        boxWednesday.titleLabel.stringValue = "Wed"
        boxTuesday.titleLabel.stringValue = "Tue"
        boxMonday.titleLabel.stringValue = "Mon"
        
        boxSunday.index = 1
        boxSaturday.index = 7
        boxFriday.index = 6
        boxThursday.index = 5
        boxWednesday.index = 4
        boxTuesday.index = 3
        boxMonday.index = 2
        
        arrAllWeekDayBox = [boxSunday, boxMonday, boxTuesday, boxWednesday, boxThursday, boxFriday, boxSaturday]
        
        textFieldScheduleName.focusRingType = .none
        btnInfoStrictnessLevel.isAutoClickEnabled = false
        
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 2, progress: 0.30)
    }

    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "create-first-blocking-schedule-screen-shown", metadata: [:])
        showSelectedStrictnessLevel()
    }
    
    override func viewDidAppear() {
        // Show bubble
        var bubbleText = "For example, block distracting websites during work hours"
        if let info = configjson.value(forKey: "createFirstBlockingScheduleVcInfo") as? NSDictionary{
            bubbleText = info.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: 20, horizontalOffset: 25, fontSize: 13)
        }
    }
    
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    func resetData(){
        for box in arrAllWeekDayBox{
            box.isSelected = false
        }
        
        
        arrFocusTypeForBlockingSchedule.removeAll()
        for i in 0..<arrFocusType.count{
            if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true){
                arrFocusTypeForBlockingSchedule.append(arrFocusType[i])
            }
        }
        
        
        textFieldScheduleName.stringValue = ""
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        for box in arrAllWeekDayBox{
            if box.index == weekday{
                box.isSelected = true
                break;
            }
        }
        
        blockMode = ._NORMAL_
        sliderStrictness.integerValue = 1
        checkBoxAiEnabled.state = .on
        checkBoxSkipMicroBreaks.state = .on
        
        let now = Date()
        
        // From = current time + 2 minutes
        let from = Calendar.current.date(byAdding: .minute, value: 2, to: now)!
        
        // Till = from + 1 hour
        let till = Calendar.current.date(byAdding: .hour, value: 1, to: from)!
        datePickerFrom.dateValue = from
        datePickerTill.dateValue = till
        
        showSelectedStrictnessLevel()
        
        textFieldScheduleName.setFocus()
        scrollView.scrollToTop()
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
    
    func closeView(){
        tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()
        addLog(text: "blockingScheduleEditorVC:- closeView")//2.27.421
    }

    func showAlert(title:String){
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = title
        alert.addButton(withTitle: buttonOkText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
            
            
        })
    }
    
    @IBAction func btnAddBlockClicked(_ sender: Any) {
        addLog(text: "[user-action] blockingScheduleEditorVC:- button Save Clicked")//2.27.421
        if textFieldScheduleName.stringValue.isEmpty{
            
            var alertEnterName = "Please enter a name for your custom schedule before saving."
            if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                alertEnterName = blockingScheduleEditorVcInfo.value(forKey: "alertEnterName") as? String ?? alertEnterName
            }
            showAlert(title: alertEnterName)
            
            addLog(text: "showAlert:- empty name")//2.27.421
            return;
        }
        
        var arrDays = [Int]()
        
        for box in arrAllWeekDayBox{
            if box.isSelected{
                arrDays.append(box.index)
            }
        }
        
        if arrDays.count == 0{
            var alertSelectDay = "Please select at least one day for this schedule."
            if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                alertSelectDay = blockingScheduleEditorVcInfo.value(forKey: "alertSelectDay") as? String ?? alertSelectDay
            }
            showAlert(title: alertSelectDay)
            
            addLog(text: "showAlert:- empty days array")//2.27.421
            return;
        }

        if sliderStrictness.integerValue == 1{
            addLog(text: "strictness level is normal mode")
            blockMode = ._NORMAL_
        }else if sliderStrictness.integerValue == 2{
            addLog(text: "strictness level is strict mode")
            blockMode = ._STRICT_
        }else if sliderStrictness.integerValue == 3{
            addLog(text: "strictness level is super strict mode")
            blockMode = ._SUPER_STRICT_
        }
        
        let blockingSchedule = customBlockingSchedule(
            id: UUID().uuidString,
            name: textFieldScheduleName.stringValue,
            start: getTimeString(date: datePickerFrom.dateValue),
            end: getTimeString(date: datePickerTill.dateValue),
            daysOfWeek: arrDays,
            focusModeID: "",
            blockLevel: blockMode,
            isAIBlockingEnabled: checkBoxAiEnabled.state == .on, isMicroBreaksEnabled: checkBoxSkipMicroBreaks.state != .on
        )
        customBlockingScheduleManagerObj.pendingFirstBlockingSchedule = blockingSchedule
        getOnboardingVcObject().navigate(to: ._ASK_PERMISSIONS_)
    }

    
    func getTimeString(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    
    @IBAction func checkBoxSkipMicroBreaksClicked(_ sender: Any) {
    }
    
    @IBAction func checkBoxAiEnabledClicked(_ sender: Any) {
        
    }
    
    @IBAction func btnInfoSkipMicroBreaksClicked(_ sender: Any) {
        var toolTip = "Focused work sessions! Activate this setting to automatically skip micro breaks when engaged in work blocks, maintaining an unbroken flow for sustained concentration and efficiency."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "pomodoro_Advanced_SkipBreaks") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSkipMicroBreaks, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    
    @IBAction func btnInfoIUseAiClicked(_ sender: Any) {
        var toolTipAiBlocking = "When you open a website you haven't specifically blocked or allowed, we'll use AI to check whether the website is relevant or not based on your focus intention. In strict mode, it will block it immediately if it's not relevant. In non strict mode, it will show a popup asking whether you really need it."
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            toolTipAiBlocking = simplePomodoroVcInfo.value(forKey: "toolTipAiBlocking") as? String ?? toolTipAiBlocking
        }
        showTooltip(sender: btnInfoIUseAi, msg: toolTipAiBlocking, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
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
        showSelectedStrictnessLevel()
    }
}
