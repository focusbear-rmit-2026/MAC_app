//
//  createFirstBlockingScheduleVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 28/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

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

    // #2274: onboarding reuses the in-app SwiftUI blocking-schedule editor so the two screens match.
    private var editorModel: Any?            // BlockingScheduleEditorModel (macOS 11+)
    private var editorHostingView: NSView?
    
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
        
        var daySun = "Sun"
        var daySat = "Sat"
        var dayFri = "Fri"
        var dayThu = "Thu"
        var dayWed = "Wed"
        var dayTue = "Tue"
        var dayMon = "Mon"
        
        if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
            lblTitleScheduleName.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleScheduleName") as? String ?? lblTitleScheduleName.stringValue
            lblTitleScheduleDays.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleBlockingSchedule") as? String ?? lblTitleScheduleDays.stringValue
            lblTitleFromTime.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleFromTime") as? String ?? lblTitleFromTime.stringValue
            lblTitleTillTime.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleTillTime") as? String ?? lblTitleTillTime.stringValue
            checkBoxSkipMicroBreaks.title = blockingScheduleEditorVcInfo.value(forKey: "buttonSkipMicrobreaks") as? String ?? checkBoxSkipMicroBreaks.title
            checkBoxAiEnabled.title = blockingScheduleEditorVcInfo.value(forKey: "buttonEnableAi") as? String ?? checkBoxAiEnabled.title
            
            daySun = blockingScheduleEditorVcInfo.value(forKey: "daySun") as? String ?? daySun
            daySat = blockingScheduleEditorVcInfo.value(forKey: "daySat") as? String ?? daySat
            dayFri = blockingScheduleEditorVcInfo.value(forKey: "dayFri") as? String ?? dayFri
            dayThu = blockingScheduleEditorVcInfo.value(forKey: "dayThu") as? String ?? dayThu
            dayWed = blockingScheduleEditorVcInfo.value(forKey: "dayWed") as? String ?? dayWed
            dayTue = blockingScheduleEditorVcInfo.value(forKey: "dayTue") as? String ?? dayTue
            dayMon = blockingScheduleEditorVcInfo.value(forKey: "dayMon") as? String ?? dayMon
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

        
        
        boxSunday.titleLabel.stringValue = daySun
        boxSaturday.titleLabel.stringValue = daySat
        boxFriday.titleLabel.stringValue = dayFri
        boxThursday.titleLabel.stringValue = dayThu
        boxWednesday.titleLabel.stringValue = dayWed
        boxTuesday.titleLabel.stringValue = dayTue
        boxMonday.titleLabel.stringValue = dayMon
        
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
        getDistractionBlockingProgressVcObj().setProgress(level: 2, progress: 0.70)

        setupSwiftUIEditor()
    }

    // MARK: - SwiftUI editor hosting (#2274)

    /// Swap only the form area (the storyboard `scrollView` with the old date pickers / slider / day
    /// boxes / checkboxes) for the same SwiftUI editor used by the in-app Blocking Schedule settings,
    /// so the two screens match. Everything else on the screen is left untouched — the step-progress
    /// bar, the "Set Block Details" title, the bear image + bubble, and the bottom "Add Block" CTA all
    /// stay exactly where they were. Onboarding has no block list yet (no focus modes exist) and uses
    /// the storyboard's own Add-Block button, so the editor's header, footer and block-list row are
    /// hidden.
    private func setupSwiftUIEditor() {
        guard #available(macOS 11.0, *) else { return }

        // Hide the old form. The controls live inside `scrollView`, which sits inside a bordered NSBox
        // — hide the whole box so its border doesn't show around the SwiftUI editor. (A hidden view
        // keeps its layout, so `scrollView`'s anchors below still position the hosting view correctly.)
        var formBox: NSView = scrollView
        while let sv = formBox.superview, !(formBox is NSBox), sv != view { formBox = sv }
        formBox.isHidden = true

        let model = BlockingScheduleEditorModel()
        editorModel = model
        configureModel(model)

        let root = BlockingScheduleEditorView(
            model: model,
            onSave: { [weak self] in self?.saveFromModel() },
            onCancel: {},
            onDelete: {},
            onEditBlockList: {},
            onBack: {},
            showBlockList: false,
            showHeader: false,
            showCancel: false,
            showFooter: false,
            expandMoreOptions: true)

        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // Pin the hosting view over the (now hidden) scroll view's frame so it occupies the same
        // form region. A hidden view keeps its layout, so these anchors track the old form box.
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])
        editorHostingView = hosting
    }

    /// Seed the editor model with onboarding defaults (mirrors the old `resetData`): empty name,
    /// today's weekday selected, a one-hour window starting two minutes from now, flexible strictness,
    /// AI on, microbreaks skipped. There is deliberately no block-list selection during onboarding.
    @available(macOS 11.0, *)
    private func configureModel(_ model: BlockingScheduleEditorModel) {
        model.isEditing = false
        model.name = ""
        model.selectedDays = [2, 3, 4, 5, 6]   // default to the "Weekdays" scope (Mon–Fri)
        let now = Date()
        let from = Calendar.current.date(byAdding: .minute, value: 2, to: now) ?? now
        let till = Calendar.current.date(byAdding: .hour, value: 1, to: from) ?? from
        model.startMinutes = minutesFromDate(from)
        model.endMinutes = minutesFromDate(till)
        if model.endMinutes <= model.startMinutes { model.endMinutes = min(1440, model.startMinutes + 60) }
        model.strictness = ._NORMAL_
        model.useAI = true
        model.skipMicroBreaks = true
    }

    /// Reset the editor to onboarding defaults and, when the user picked a quick-start preset on the
    /// previous step, overlay that preset's name/emoji/days/time/strictness. "Custom Schedule" leaves
    /// nil, so the editor stays blank. Called from onboardingVc on every entry to _CREATE_BLOCKING_SCHEDULE_
    /// (the VC is a singleton, so viewDidLoad — and its one-time configureModel — won't re-run). The
    /// preset is consumed here so it doesn't leak into a later visit.
    @available(macOS 11.0, *)
    func applyOnboardingScheduleTemplate() {
        guard let model = editorModel as? BlockingScheduleEditorModel else { return }
        configureModel(model)
        if let preset = getOnboardingVcObject().chosenSchedulePreset, !preset.isCustom {
            model.name = preset.name
            model.emoji = preset.emoji
            model.selectedDays = Set(preset.days)
            model.startMinutes = preset.startMinutes
            model.endMinutes = preset.endMinutes
            model.strictness = preset.strictness
        }
        getOnboardingVcObject().chosenSchedulePreset = nil
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// Save handler driven by the SwiftUI editor. Mirrors `btnAddBlockClicked` but reads the SwiftUI
    /// model and never asks for a block list (onboarding has none — `focusModeID` stays "").
    @available(macOS 11.0, *)
    private func saveFromModel() {
        guard let model = editorModel as? BlockingScheduleEditorModel else { return }
        addLog(text: "[user-action] createFirstBlockingScheduleVc:- Add Block (SwiftUI) clicked")

        if model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var alertEnterName = "Please enter a name for your custom schedule before saving."
            if let info = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary {
                alertEnterName = info.value(forKey: "alertEnterName") as? String ?? alertEnterName
            }
            showAlert(title: alertEnterName)
            addLog(text: "showAlert:- empty name")
            return
        }

        let arrDays = Array(model.selectedDays).sorted()
        if arrDays.isEmpty {
            var alertSelectDay = "Please select at least one day for this schedule."
            if let info = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary {
                alertSelectDay = info.value(forKey: "alertSelectDay") as? String ?? alertSelectDay
            }
            showAlert(title: alertSelectDay)
            addLog(text: "showAlert:- empty days array")
            return
        }

        blockMode = model.strictness
        let blockingSchedule = customBlockingSchedule(
            id: UUID().uuidString,
            name: model.name,
            start: BlockingScheduleStore.hhmm(fromMinutes: model.startMinutes),
            end: BlockingScheduleStore.hhmm(fromMinutes: model.endMinutes),
            daysOfWeek: arrDays,
            focusModeID: "",
            blockLevel: blockMode,
            isAIBlockingEnabled: model.useAI,
            isMicroBreaksEnabled: !model.skipMicroBreaks,
            emoji: model.emoji
        )
        customBlockingScheduleManagerObj.pendingFirstBlockingSchedule = blockingSchedule
        getOnboardingVcObject().navigate(to: ._ASK_PERMISSIONS_)
    }

    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "create-first-blocking-schedule-screen-shown", metadata: [:])
        showSelectedStrictnessLevel()
        // Default the window to the shared new-schedule defaults. Without this the storyboard's
        // useCurrentDate leaves both pickers at the current time.
        datePickerFrom.dateValue = Self.date(atMinuteOfDay: BlockingScheduleDefaults.startMinutes)
        datePickerTill.dateValue = Self.date(atMinuteOfDay: BlockingScheduleDefaults.endMinutes)
    }

    /// Today at the given minute-of-day — the date pickers are time-only, so the day part is ignored.
    private static func date(atMinuteOfDay minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
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
        
        blockMode = BlockingScheduleDefaults.strictness
        sliderStrictness.integerValue = 1
        checkBoxAiEnabled.state = BlockingScheduleDefaults.isAIEnabled ? .on : .off
        checkBoxSkipMicroBreaks.state = BlockingScheduleDefaults.skipMicroBreaks ? .on : .off

        datePickerFrom.dateValue = Self.date(atMinuteOfDay: BlockingScheduleDefaults.startMinutes)
        datePickerTill.dateValue = Self.date(atMinuteOfDay: BlockingScheduleDefaults.endMinutes)
        
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
        // #2274: the form is now the SwiftUI editor; this storyboard CTA just drives its save path.
        if #available(macOS 11.0, *) { saveFromModel() }
    }

    
    func getTimeString(date:Date) -> String {
        MachineDateFormat.string(from: date, format: MachineDateFormat.clockTime)
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
