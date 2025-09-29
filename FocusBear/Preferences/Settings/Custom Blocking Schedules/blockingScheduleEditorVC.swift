//
//  blockingScheduleEditorVC.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

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
        
        btnSave.title = "Save changes"
        btnDelete.title = "Delete"
        
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        btnCancel.title = buttonCancelText
        
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
        
        btnCancel.buttonColor = NSColor.white.cgColor
        btnDelete.buttonColor = NSColor.white.cgColor

    
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
        
//        boxSunday.titleLabel = boxSunday.index.
        arrAllWeekDayBox = [boxSunday, boxMonday, boxTuesday, boxWednesday, boxThursday, boxFriday, boxSaturday]
        
        textFieldScheduleName.focusRingType = .none
        btnInfoStrictnessLevel.isAutoClickEnabled = false

        btnEditBlockList.isHidden = false
    }
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here
        btnSave.title = btnSave.title
        btnCancel.title = btnCancel.title
        btnDelete.title = btnDelete.title
    }
    
    func reloadFocusModeList(){
        let selectedIndex = popUpBtnFocusMode.indexOfSelectedItem
        arrFocusTypeForBlockingSchedule.removeAll()
        for i in 0..<arrFocusType.count{
            if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true){
                arrFocusTypeForBlockingSchedule.append(arrFocusType[i])
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
        for box in arrAllWeekDayBox{
            box.isSelected = false
        }
        arrFocusTypeForBlockingSchedule.removeAll()
        for i in 0..<arrFocusType.count{
            if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true){
                arrFocusTypeForBlockingSchedule.append(arrFocusType[i])
            }
        }
        
        if shouldCreateNew{
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
            
//            btnEditBlockList.isHidden = true
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
            
            for i in 0..<arrFocusTypeForBlockingSchedule.count{
                if let id = arrFocusTypeForBlockingSchedule[i]["id"] as? String{
                    if id == focusModeId{
                        popUpBtnFocusMode.selectItem(at: i)
                        break;
                    }
                }
            }
//            btnEditBlockList.isHidden = false
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
//        if isCreatingNew{
//            if index == 0{
//                showAlert(title: "A focus mode must be selected before saving this schedule.")
//                addLog(text: "showAlert:- focus mode must be selected")//2.27.
//                return;
//            }
//            index = index - 1
//        }
        
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
        
        let blockingSchedule = customBlockingSchedule(
            name: textFieldScheduleName.stringValue,
            start: getTimeString(date: datePickerFrom.dateValue),
            end: getTimeString(date: datePickerTill.dateValue),
            daysOfWeek: arrDays,
            focusModeID: focusModeId,
            //pauseFriction: .timer,
            blockLevel: blockMode,
            isAIBlockingEnabled: checkBoxAiEnabled.state == .on, isMicroBreaksEnabled: checkBoxSkipMicroBreaks.state != .on 
        )
        if isCreatingNew{
            // Create a new schedule
            customBlockingScheduleManagerObj.arrBlockingSchedule.append(blockingSchedule)
            customBlockingSchedulesVcObj?.scheduleAdded()
            allApiObject.capturePosthog(event: "add-blocking-schedule", metadata: [:])//2.27.421
        }else{
            customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex] = blockingSchedule
            customBlockingSchedulesVcObj?.scheduleEditedAt(currentFocusModeIndex)
            allApiObject.capturePosthog(event: "edit-blocking-schedule", metadata: [:])//2.27.421
        }
        
        
        closeView()
    }
    
    func getTimeString(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
        allApiObject.capturePosthog(event: "open-preferences", metadata: [:])// todo
        addLog(text: "[user-action]Showing preferences from edit focus mode")
        
        self.presentAsSheet(getFocusPreferencesVcObject()) // no password needed beacause we are already inside settings
        let index = popUpBtnFocusMode.indexOfSelectedItem
//        if isCreatingNew{
//            index = index - 1
//        }
        
        if let focusModeId = arrFocusTypeForBlockingSchedule[index]["id"] as? String{
            getFocusPreferencesVcObject().selectFocusModeWithId(id: focusModeId)
        }
        getFocusPreferencesVcObject().btnBackToCustomBlocking.isHidden = false
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
