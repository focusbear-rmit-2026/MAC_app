//
//  blockingScheduleEditorVC.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

class blockingScheduleEditorVC: NSViewController {
    
    
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
    @IBOutlet weak var btnEditBlockList: underLineButton!
    @IBOutlet weak var popUpBtnFocusMode: NSPopUpButton!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var boxBlockingModes: NSBox!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnDelete: Button!
    @IBOutlet weak var btnSave: Button!
    

    @IBOutlet weak var lblTitleFocusMode: NSTextField!
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
    @IBOutlet weak var btnBack: cursorButton!
    
    
    var blockMode:FOCUSMODESTRICTNESS = ._NORMAL_
    var arrAllWeekDayBox = [toggleTitledBox]()
    var focusModeDefaultIndex = 0
    var arrFocusTypeForBlockingSchedule = [[String : Any]]()
    var isCreatingNew = false
    var currentFocusModeIndex = 0

    // Pre-fill values when a schedule is drag-created on the calendar redesign
    // or created from a Quick-Start preset.
    var prefillDays: [Int]?
    var prefillStart: Date?
    var prefillEnd: Date?
    var prefillName: String?
    var prefillStrictness: FOCUSMODESTRICTNESS?
    var prefillEmoji: String?

    // SwiftUI editor hosting (Figma redesign). The model is configured from
    // resetData(); the SwiftUI view calls back into this VC's save/delete/etc.
    private var editorModel: Any?            // BlockingScheduleEditorModel (macOS 11+)
    private var editorHostingView: NSView?
    
    var titleNormalMode = "Chill Mode"
    var descriptionNormalMode = "Stop focusing anytime, no questions asked."
    var toolTipNormalMode = "Best for gentle focus days. No barriers to pausing or stopping a session."
    var titleStrictMode = "Wait for it…"
    var descriptionStrictMode = "15-second delay before you can stop"
    var toolTipStrictMode = "Adds a 15s countdown before you can pause/stop. Great for catching impulsive decisions."
    var titleSuperStrictMode = "Iron Focus"
    var descriptionSuperStrictMode = "Once you start, you can't stop"
    var toolTipSuperStrictMode = "Once you start, there’s no backing out. Best for deep, distraction-free sessions."
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        lblTitle.stringValue = "Custom Blocking"
        lblTitleScheduleName.stringValue = "Block name"
        lblTitleScheduleDays.stringValue = "Blocking schedule"
        lblTitleFromTime.stringValue = "From"
        lblTitleTillTime.stringValue = "Till"
        lblTitleFocusMode.stringValue = "Block list"
        btnEditBlockList.title = "Edit block list"
        checkBoxSkipMicroBreaks.title = "Skip microbreaks"
        checkBoxAiEnabled.title = "Use Al to decide if websites should be allowed"
        // "Use AI" is a per-block-list setting now (owned by the block list, synced to the server — see
        // CLAUDE.md), NOT a per-schedule option. Hide it here so schedules no longer expose it; a schedule
        // just runs its block list, and that block list's is_ai_enabled governs AI relevance.
        checkBoxAiEnabled.isHidden = true

        btnSave.title = "Save changes"
        btnDelete.title = "Delete"
        
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        btnCancel.title = buttonCancelText
        
        var daySun = "Sun"
        var daySat = "Sat"
        var dayFri = "Fri"
        var dayThu = "Thu"
        var dayWed = "Wed"
        var dayTue = "Tue"
        var dayMon = "Mon"
        
        if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
            lblTitle.stringValue = blockingScheduleEditorVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleScheduleName.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleScheduleName") as? String ?? lblTitleScheduleName.stringValue
            lblTitleScheduleDays.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleBlockingSchedule") as? String ?? lblTitleScheduleDays.stringValue
            lblTitleFromTime.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleFromTime") as? String ?? lblTitleFromTime.stringValue
            lblTitleTillTime.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleTillTime") as? String ?? lblTitleTillTime.stringValue
            lblTitleFocusMode.stringValue = blockingScheduleEditorVcInfo.value(forKey: "titleFocusMode") as? String ?? lblTitleFocusMode.stringValue
            btnEditBlockList.title = blockingScheduleEditorVcInfo.value(forKey: "buttonEditBlockList") as? String ?? btnEditBlockList.title
            checkBoxSkipMicroBreaks.title = blockingScheduleEditorVcInfo.value(forKey: "buttonSkipMicrobreaks") as? String ?? checkBoxSkipMicroBreaks.title
            checkBoxAiEnabled.title = blockingScheduleEditorVcInfo.value(forKey: "buttonEnableAi") as? String ?? checkBoxAiEnabled.title
            btnSave.title = blockingScheduleEditorVcInfo.value(forKey: "buttonSave") as? String ?? btnSave.title
            btnDelete.title = blockingScheduleEditorVcInfo.value(forKey: "buttonDelete") as? String ?? btnDelete.title
            
            daySun = blockingScheduleEditorVcInfo.value(forKey: "daySun") as? String ?? daySun
            daySat = blockingScheduleEditorVcInfo.value(forKey: "daySat") as? String ?? daySat
            dayFri = blockingScheduleEditorVcInfo.value(forKey: "dayFri") as? String ?? dayFri
            dayThu = blockingScheduleEditorVcInfo.value(forKey: "dayThu") as? String ?? dayThu
            dayWed = blockingScheduleEditorVcInfo.value(forKey: "dayWed") as? String ?? dayWed
            dayTue = blockingScheduleEditorVcInfo.value(forKey: "dayTue") as? String ?? dayTue
            dayMon = blockingScheduleEditorVcInfo.value(forKey: "dayMon") as? String ?? dayMon
            
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
        
        btnCancel.isSecondaryButton = true
        btnDelete.isSecondaryButton = true

        
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

        btnEditBlockList.isHidden = false

        setupSwiftUIEditor()
    }

    // MARK: - SwiftUI editor hosting

    private func setupSwiftUIEditor() {
        guard #available(macOS 11.0, *) else { return }

        // The redesign overlays a full-bleed SwiftUI editor on top of this storyboard scene. Hide all
        // the storyboard-provided controls first so they don't render or intercept hover/clicks behind
        // the SwiftUI view (otherwise the hand cursor / clicks fall through to the old controls in the
        // SwiftUI view's transparent areas). Outlets still exist for any code that reads them — they're
        // just hidden. The hosting view is added afterwards, so it stays visible.
        view.subviews.forEach { $0.isHidden = true }

        let model = BlockingScheduleEditorModel()
        editorModel = model

        let root = BlockingScheduleEditorView(
            model: model,
            onSave: { [weak self] in self?.saveFromModel() },
            onCancel: { [weak self] in self?.closeView() },
            onDelete: { [weak self] in self?.deleteFromModel() },
            onEditBlockList: { [weak self] in self?.editBlockListFromModel() },
            onBack: { [weak self] in self?.closeView() })

        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        editorHostingView = hosting
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // refresh block lists in case the user edited them in the sheet
        if #available(macOS 11.0, *), let model = editorModel as? BlockingScheduleEditorModel {
            model.reloadFocusModes()
        }
    }

    /// Populate the SwiftUI editor model from the schedule being edited / created.
    @available(macOS 11.0, *)
    private func configureModel(index: Int, shouldCreateNew: Bool) {
        guard let model = editorModel as? BlockingScheduleEditorModel else { return }
        model.reloadFocusModes()
        if shouldCreateNew {
            model.name = prefillName ?? ""
            model.selectedDays = prefillDays.map { Set($0) } ?? [1, 2, 3, 4, 5, 6, 7]
            model.strictness = prefillStrictness ?? BlockingScheduleDefaults.strictness
            model.emoji = prefillEmoji
            // A slot dragged on the calendar (or a preset) still wins; without one the schedule starts
            // at the shared workday default rather than "two minutes from now, for an hour".
            model.applyNewScheduleDefaults(startMinutes: prefillStart.map { minutesFromDate($0) },
                                           endMinutes: prefillEnd.map { minutesFromDate($0) })
            if model.selectedFocusModeID == nil { model.selectedFocusModeID = model.focusModes.first?.id }
            prefillEmoji = nil
        } else {
            let s = customBlockingScheduleManagerObj.arrBlockingSchedule[index]
            model.name = s.name
            model.selectedDays = Set(s.daysOfWeek)
            model.strictness = s.blockLevel
            model.emoji = s.emoji
            model.selectedFocusModeID = s.focusModeID
            model.applySavedSchedule(startMinutes: BlockingScheduleStore.minutes(from: s.startTimeString),
                                     endMinutes: BlockingScheduleStore.minutes(from: s.endTimeString),
                                     isAIBlockingEnabled: s.isAIBlockingEnabled,
                                     isMicroBreaksEnabled: s.isMicroBreaksEnabled)
        }
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// Save handler driven by the SwiftUI model (mirrors btnSaveClicked).
    @available(macOS 11.0, *)
    private func saveFromModel() {
        guard let model = editorModel as? BlockingScheduleEditorModel else { return }

        if model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var alertEnterName = "Please enter a name for your custom schedule before saving."
            if let info = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary {
                alertEnterName = info.value(forKey: "alertEnterName") as? String ?? alertEnterName
            }
            showAlert(title: alertEnterName); return
        }
        let days = Array(model.selectedDays).sorted()
        if days.isEmpty {
            var alertSelectDay = "Please select at least one day for this schedule."
            if let info = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary {
                alertSelectDay = info.value(forKey: "alertSelectDay") as? String ?? alertSelectDay
            }
            showAlert(title: alertSelectDay); return
        }
        guard let focusModeId = model.selectedFocusModeID, !focusModeId.isEmpty else {
            var alertSelectBlockList = "Please select block list."
            if let info = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary {
                alertSelectBlockList = info.value(forKey: "alertSelectBlockList") as? String ?? alertSelectBlockList
            }
            showAlert(title: alertSelectBlockList); return
        }

        blockMode = model.strictness
        let startStr = BlockingScheduleStore.hhmm(fromMinutes: model.startMinutes)
        let endStr = BlockingScheduleStore.hhmm(fromMinutes: model.endMinutes)

        if model.isEditing {
            if customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].state == .on {
                currentFocusModeStrictness = blockMode
            }
            var blockingSchedule = customBlockingSchedule(
                id: customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].id,
                name: model.name, start: startStr, end: endStr, daysOfWeek: days,
                focusModeID: focusModeId, blockLevel: blockMode,
                isAIBlockingEnabled: model.useAI, isMicroBreaksEnabled: !model.skipMicroBreaks,
                emoji: model.emoji)
            blockingSchedule.state = customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].state
            isCreatingNew = false
            if customBlockingScheduleManagerObj.isBlockingScheduleOverlapping(newSchedule: blockingSchedule, schedules: customBlockingScheduleManagerObj.arrBlockingSchedule, excludingId: blockingSchedule.id) {
                showOverlapAlert(for: blockingSchedule); return
            }
            editBlockingSchedule(blockingSchedule: blockingSchedule)
        } else {
            let blockingSchedule = customBlockingSchedule(
                id: UUID().uuidString,
                name: model.name, start: startStr, end: endStr, daysOfWeek: days,
                focusModeID: focusModeId, blockLevel: blockMode,
                isAIBlockingEnabled: model.useAI, isMicroBreaksEnabled: !model.skipMicroBreaks,
                emoji: model.emoji)
            isCreatingNew = true
            if customBlockingScheduleManagerObj.isBlockingScheduleOverlapping(newSchedule: blockingSchedule, schedules: customBlockingScheduleManagerObj.arrBlockingSchedule, excludingId: nil) {
                showOverlapAlert(for: blockingSchedule); return
            }
            createBlockingSchedule(blockingSchedule: blockingSchedule)
        }
    }

    @available(macOS 11.0, *)
    private func deleteFromModel() {
        guard currentFocusModeIndex >= 0,
              currentFocusModeIndex < customBlockingScheduleManagerObj.arrBlockingSchedule.count else { return }
        confirmDelete(schedule: customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex], at: currentFocusModeIndex)
    }

    @available(macOS 11.0, *)
    private func editBlockListFromModel() {
        addLog(text: "[user-action]Showing preferences from edit focus mode (SwiftUI editor)")
        if focusPreferencesVcObj == nil {
            getFocusPreferencesVcObject().loadView()
        }
        getFocusPreferencesVcObject().btnBackToCustomBlocking.isHidden = false
        getFocusPreferencesVcObject().btnBack.isHidden = true
        self.presentAsSheet(getFocusPreferencesVcObject())
        if let model = editorModel as? BlockingScheduleEditorModel, let id = model.selectedFocusModeID {
            getFocusPreferencesVcObject().selectFocusModeWithId(id: id)
        }
    }
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here
        btnSave.title = btnSave.title
        btnCancel.title = btnCancel.title
        btnDelete.title = btnDelete.title
    }
    
    func reloadFocusModeList(){
        // #2602: refresh the SwiftUI editor's block-list list so a name edited in the block-list sheet
        // shows on the schedule's selected block list. reloadFocusModes() keeps the current selection.
        if #available(macOS 11.0, *), let model = editorModel as? BlockingScheduleEditorModel {
            model.reloadFocusModes()
        }
        let selectedIndex = popUpBtnFocusMode.indexOfSelectedItem
        if selectedIndex == -1{
            return;
        }
        arrFocusTypeForBlockingSchedule.removeAll()
        for focusMode in HiddenFocusModeManager.visibleFocusModes(from: arrFocusType){
            if !(focusMode["isMeetings"] as? Bool ?? false == true){
                arrFocusTypeForBlockingSchedule.append(focusMode)
            }
        }
        popUpBtnFocusMode.removeAllItems()
        
        for i in 0..<arrFocusTypeForBlockingSchedule.count{
            if let name = arrFocusTypeForBlockingSchedule[i]["name"] as? String{
                popUpBtnFocusMode.addItem(withTitle: name)
            }
        }
        if selectedIndex < popUpBtnFocusMode.numberOfItems{
            popUpBtnFocusMode.selectItem(at: selectedIndex)
        }
    }

    func resetData(index:Int, shouldCreateNew:Bool){
        isCreatingNew = shouldCreateNew
        currentFocusModeIndex = index
        // Drive the SwiftUI editor (reads prefill values before the legacy
        // outlet code below clears them).
        if #available(macOS 11.0, *) { configureModel(index: index, shouldCreateNew: shouldCreateNew) }
        for box in arrAllWeekDayBox{
            box.isSelected = false
        }
        
        if isCreatingNew{
            btnDelete.isHidden = true
        }else{
            btnDelete.isHidden = false
        }
        
        arrFocusTypeForBlockingSchedule.removeAll()
        for focusMode in HiddenFocusModeManager.visibleFocusModes(from: arrFocusType){
            if !(focusMode["isMeetings"] as? Bool ?? false == true){
                arrFocusTypeForBlockingSchedule.append(focusMode)
            }
        }

        if shouldCreateNew{
            textFieldScheduleName.stringValue = ""
            for box in arrAllWeekDayBox{
                box.isSelected = true
            }
            
            popUpBtnFocusMode.removeAllItems()
            for i in 0..<arrFocusTypeForBlockingSchedule.count{
                if let name = arrFocusTypeForBlockingSchedule[i]["name"] as? String{
                    popUpBtnFocusMode.addItem(withTitle: name)
                }
            }
            popUpBtnFocusMode.selectItem(at: focusModeDefaultIndex)
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

            // Apply calendar drag-create / preset pre-fill.
            if let name = prefillName { textFieldScheduleName.stringValue = name }
            if let days = prefillDays {
                for box in arrAllWeekDayBox { box.isSelected = days.contains(box.index) }
            }
            if let start = prefillStart { datePickerFrom.dateValue = start }
            if let end = prefillEnd { datePickerTill.dateValue = end }
            if let strictness = prefillStrictness {
                blockMode = strictness
                switch strictness {
                case ._NORMAL_:       sliderStrictness.integerValue = 1
                case ._STRICT_:       sliderStrictness.integerValue = 2
                case ._SUPER_STRICT_: sliderStrictness.integerValue = 3
                }
            }
            prefillDays = nil
            prefillStart = nil
            prefillEnd = nil
            prefillName = nil
            prefillStrictness = nil
        }else{
            textFieldScheduleName.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[index].name
            let weekDays = customBlockingScheduleManagerObj.arrBlockingSchedule[index].daysOfWeek
            for box in arrAllWeekDayBox{
                if weekDays.contains(box.index){
                    box.isSelected = true
                }
            }
            blockMode = customBlockingScheduleManagerObj.arrBlockingSchedule[index].blockLevel
            switch blockMode {
            case ._NORMAL_:
                sliderStrictness.integerValue = 1
            case ._STRICT_:
                sliderStrictness.integerValue = 2
            case ._SUPER_STRICT_:
                sliderStrictness.integerValue = 3
            }
            
            popUpBtnFocusMode.removeAllItems()
            for i in 0..<arrFocusTypeForBlockingSchedule.count{
                if let name = arrFocusTypeForBlockingSchedule[i]["name"] as? String{
                    popUpBtnFocusMode.addItem(withTitle: name)
                }
            }
            
            
            let focusModeId = customBlockingScheduleManagerObj.arrBlockingSchedule[index].focusModeID
            popUpBtnFocusMode.selectItem(at: -1)
            for i in 0..<arrFocusTypeForBlockingSchedule.count{
                if let id = arrFocusTypeForBlockingSchedule[i]["id"] as? String{
                    if id == focusModeId{
                        popUpBtnFocusMode.selectItem(at: i)
                        break;
                    }
                }
            }
            checkBoxAiEnabled.state = customBlockingScheduleManagerObj.arrBlockingSchedule[index].isAIBlockingEnabled ? .on : .off
            checkBoxSkipMicroBreaks.state = customBlockingScheduleManagerObj.arrBlockingSchedule[index].isMicroBreaksEnabled ? .off : .on
            datePickerFrom.dateValue = customBlockingScheduleManagerObj.arrBlockingSchedule[index].startTime
            datePickerTill.dateValue = customBlockingScheduleManagerObj.arrBlockingSchedule[index].endTime
        }
        showSelectedStrictnessLevel()
        
        textFieldScheduleName.setFocus()
        scrollView.scrollToTop()
    }
    
    override func viewWillAppear() {
        showSelectedStrictnessLevel()
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
    
    @IBAction func btnBackClicked(_ sender: Any) {
        closeView()
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
    
    @IBAction func btnSaveClicked(_ sender: Any) {
        addLog(text: "[user-action]blockingScheduleEditorVC:- button Save Clicked")//2.27.421
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
        
        let index = popUpBtnFocusMode.indexOfSelectedItem
        if index == -1{// if selected focus mode is deleted then we select -1 index of popupbtn just for show blank selection
            var alertSelectBlockList = "Please select block list."
            if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                alertSelectBlockList = blockingScheduleEditorVcInfo.value(forKey: "alertSelectBlockList") as? String ?? alertSelectBlockList
            }
            showAlert(title: alertSelectBlockList)
            
            addLog(text: "showAlert:- select block list")//2.27.428
            return;
        }
        
        
        
        
        
        let focusModeId = arrFocusTypeForBlockingSchedule[index]["id"] as? String ?? ""
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
        
        
        if isCreatingNew{
            let blockingSchedule = customBlockingSchedule(
                id: UUID().uuidString,
                name: textFieldScheduleName.stringValue,
                start: getTimeString(date: datePickerFrom.dateValue),
                end: getTimeString(date: datePickerTill.dateValue),
                daysOfWeek: arrDays,
                focusModeID: focusModeId,
                //pauseFriction: .timer,
                blockLevel: blockMode,
                isAIBlockingEnabled: checkBoxAiEnabled.state == .on, isMicroBreaksEnabled: checkBoxSkipMicroBreaks.state != .on
            )
            if customBlockingScheduleManagerObj.isBlockingScheduleOverlapping(newSchedule: blockingSchedule, schedules: customBlockingScheduleManagerObj.arrBlockingSchedule, excludingId: nil){
                print("overlapping")
                showOverlapAlert(for: blockingSchedule)
                return;
            }
            
            createBlockingSchedule(blockingSchedule: blockingSchedule)
        }else{
            if customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].state == .on {
                currentFocusModeStrictness = blockMode
            }
            var blockingSchedule = customBlockingSchedule(
                id: customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].id,
                name: textFieldScheduleName.stringValue,
                start: getTimeString(date: datePickerFrom.dateValue),
                end: getTimeString(date: datePickerTill.dateValue),
                daysOfWeek: arrDays,
                focusModeID: focusModeId,
                //pauseFriction: .timer,
                blockLevel: blockMode,
                isAIBlockingEnabled: checkBoxAiEnabled.state == .on, isMicroBreaksEnabled: checkBoxSkipMicroBreaks.state != .on,
                // Carry over any per-schedule emoji set on another device — don't drop it on a Mac edit.
                emoji: customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].emoji
            )
            blockingSchedule.state = customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex].state
            
            
            if customBlockingScheduleManagerObj.isBlockingScheduleOverlapping(newSchedule: blockingSchedule, schedules: customBlockingScheduleManagerObj.arrBlockingSchedule, excludingId: blockingSchedule.id){
                showOverlapAlert(for: blockingSchedule)
                return;
            }
            
           
            editBlockingSchedule(blockingSchedule: blockingSchedule)
        }
        
    }
    
    func createBlockingSchedule(blockingSchedule: customBlockingSchedule){
        customBlockingScheduleManagerObj.arrBlockingSchedule.append(blockingSchedule)
        customBlockingScheduleManagerObj.saveBlockingSchedulesToLocal()
        customBlockingSchedulesVcObj?.scheduleAdded()
        allApiObject.capturePosthog(event: "add-blocking-schedule", metadata: [:])//2.27.421
        customBlockingScheduleManagerObj.addCustomBlockingScheduleAtIndex(customBlockingScheduleManagerObj.arrBlockingSchedule.count - 1)
        closeView()
        if customBlockingScheduleManagerObj.arrBlockingSchedule.count == 1{// v 2.28.447
            customBlockingSchedulesVcObj?.firstScheduleCreatedCheckPermissions()
        }
    }
    
    func editBlockingSchedule(blockingSchedule: customBlockingSchedule){
        customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex] = blockingSchedule
        customBlockingSchedulesVcObj?.scheduleEditedAt(currentFocusModeIndex)
        allApiObject.capturePosthog(event: "edit-blocking-schedule", metadata: [:])//2.27.421
        customBlockingScheduleManagerObj.updateCustomBlockingScheduleAtIndex(currentFocusModeIndex)
        closeView()
        customBlockingScheduleManagerObj.updateEditedBlockingScheduleEndTimeIfRunning(index: currentFocusModeIndex)
        customBlockingScheduleManagerObj.saveBlockingSchedulesToLocal()
    }
    
    func showOverlapAlert(for blockingSchedule: customBlockingSchedule) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Time Overlap Detected"
        alert.informativeText = "This blocking schedule's time overlaps with an existing one. Do you want to save it anyway?"
        var buttonSaveBlockAnyway = "Save Anyway"
        
        if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
            alert.messageText = blockingScheduleEditorVcInfo.value(forKey: "titleScheduleOverlapAlert") as? String ?? alert.messageText
            alert.informativeText = blockingScheduleEditorVcInfo.value(forKey: "subTitleScheduleOverlapAlert") as? String ?? alert.informativeText
            buttonSaveBlockAnyway = blockingScheduleEditorVcInfo.value(forKey: "buttonSaveBlockAnyway") as? String ?? buttonSaveBlockAnyway
        }
        
        alert.addButton(withTitle: buttonSaveBlockAnyway)
        alert.addButton(withTitle: buttonCancelText)
        
        // Present as a sheet if possible
        if let window = self.view.window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    if self.isCreatingNew{
                        self.createBlockingSchedule(blockingSchedule: blockingSchedule)
                    }else{
                        self.editBlockingSchedule(blockingSchedule: blockingSchedule)
                    }
                    
                }
            }
        }
    }
    
    func getTimeString(date:Date) -> String {
        MachineDateFormat.string(from: date, format: MachineDateFormat.clockTime)
    }
    
    
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        closeView()
    }
    
    @IBAction func btnDeleteClicked(_ sender: Any) {
        addLog(text: "[user-action]blockingScheduleEditorVC:- button Delete Clicked")//2.27.421
        confirmDelete(schedule: customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex], at: currentFocusModeIndex)
    }
    
    
    func confirmDelete(schedule: customBlockingSchedule, at index: Int) {
        if schedule.state == .on {
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Schedule is Active"
            alert.informativeText = "This schedule is currently running. Are you sure you want to delete it? Blocking will stop immediately."
            var buttonDelete = "Delete"
            
            if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                alert.messageText = blockingScheduleEditorVcInfo.value(forKey: "alertScheduleActive") as? String ?? alert.messageText
                alert.informativeText = blockingScheduleEditorVcInfo.value(forKey: "descriptionScheduleActive") as? String ?? alert.informativeText
                buttonDelete = blockingScheduleEditorVcInfo.value(forKey: "buttonDelete") as? String ?? buttonDelete
            }
            
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: buttonDelete)
            alert.addButton(withTitle: buttonCancelText)
            
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: {result in
                if result == .alertFirstButtonReturn{
                    customBlockingScheduleManagerObj.deleteScheduleAt(self.currentFocusModeIndex)
                    addLog(text: "Deleted running schedule: \(schedule.name)")
                    customBlockingSchedulesVcObj?.tblView.reloadData()
                    self.closeView()
                }
            })
        } else {
            customBlockingScheduleManagerObj.deleteScheduleAt(currentFocusModeIndex)
            addLog(text: "Deleted schedule: \(schedule.name)")
            customBlockingSchedulesVcObj?.tblView.reloadData()
            closeView()
        }
    }
    
    
    @IBAction func popUpBtnFocusModeClicked(_ sender: Any) {
    }
    
    @IBAction func btnEditBlockListClicked(_ sender: Any) {
        addLog(text: "[user-action]Showing preferences from edit focus mode")
        if focusPreferencesVcObj == nil{
            getFocusPreferencesVcObject().loadView()
        }
        getFocusPreferencesVcObject().btnBackToCustomBlocking.isHidden = false
        getFocusPreferencesVcObject().btnBack.isHidden = true
        self.presentAsSheet(getFocusPreferencesVcObject()) // no password needed beacause we are already inside settings
        var index = popUpBtnFocusMode.indexOfSelectedItem
        if index == -1{//if selected index is -1 reason is selected focus mode was deleted so we select at -1 to show none selected
            index = 0
        }
        if let focusModeId = arrFocusTypeForBlockingSchedule[index]["id"] as? String{
            getFocusPreferencesVcObject().selectFocusModeWithId(id: focusModeId)
        }
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

/*
 
 "blockingScheduleEditorVcInfo":{
     "title": "Custom Blocking",
     "titleSetTabLimit": "Block name",
     "titleTabLimitCount": "Blocking schedule",
     "buttonSave": "From",
     "buttonSave": "Till",
     "buttonSave": "Block list",
     "buttonSave": "Edit block list",
     "buttonSave": "Skip microbreaks",
     "buttonSave": "Use Al to decide if websites should be allowed",
     
 },
 
 */
