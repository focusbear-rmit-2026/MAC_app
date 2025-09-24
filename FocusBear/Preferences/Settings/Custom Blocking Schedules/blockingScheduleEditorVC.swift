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
    
    @IBOutlet weak var btnInfoIUseAi: NSButton!
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
    var titleAfterPostpone = "What do you want to do instead of your habits?"
    
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
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        titleNormalMode = "Normal"
        titleStrictMode = "Strict"
        titleSuperStrictMode = "Super strict"
        
        lblStrictnessNormal.stringValue = "🟢 " + titleNormalMode
        lblStrictnessStrict.stringValue = "🟡 " + titleStrictMode
        lblStrictnessSuperStrict.stringValue = "🔴 " + titleSuperStrictMode
        
        btnCancel.buttonColor = NSColor.white.cgColor // todo text all
        btnDelete.buttonColor = NSColor.white.cgColor

        boxSunday.title = "Sun"
        boxSunday.titleLabel.stringValue = "Sun"
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
        
        
        
        btnCancel.title = buttonCancelText
        btnSave.title = "Save changes"
        btnDelete.title = "Delete" // todo text
        
//        boxBlockingModes.wantsLayer = true
//        boxBlockingModes.layer?.cornerRadius = boxBlockingModes.cornerRadius
//        boxBlockingModes.layer?.borderColor =   NSColor.
        
        textFieldScheduleName.focusRingType = .none
        btnInfoStrictnessLevel.isAutoClickEnabled = false
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
        if isCreatingNew{
            popUpBtnFocusMode.addItem(withTitle: "Choose a Focus Mode to manage your blocked list")// todo text
        }
        
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
            
            btnEditBlockList.isHidden = true
            popUpBtnFocusMode.removeAllItems()
            popUpBtnFocusMode.addItem(withTitle: "Choose a Focus Mode to manage your blocked list")// todo text
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
            btnEditBlockList.isHidden = false
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
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        closeView()
    }
    
    func showAlert(title:String){
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = title // todo text all alert messages
        alert.addButton(withTitle: buttonOkText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
            
            
        })
    }
    
    @IBAction func btnSaveClicked(_ sender: Any) {
        if textFieldScheduleName.stringValue.isEmpty{
            showAlert(title: "Please enter a name for your custom schedule before saving.")
            return;
        }
        
        var arrDays = [Int]()
        
        for box in arrAllWeekDayBox{
            if box.isSelected{
                arrDays.append(box.index)
            }
        }
        
        if arrDays.count == 0{
            showAlert(title: "Please select at least one day for this schedule.")
            return;
        }
        
        var index = popUpBtnFocusMode.indexOfSelectedItem
        if isCreatingNew{
            if index == 0{
                showAlert(title: "A focus mode must be selected before saving this schedule.")
                return;
            }
            index = index - 1
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
        }else{
            customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex] = blockingSchedule
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
        confirmDelete(schedule: customBlockingScheduleManagerObj.arrBlockingSchedule[currentFocusModeIndex], at: currentFocusModeIndex)
    }
    
    
    func confirmDelete(schedule: customBlockingSchedule, at index: Int) {
        if schedule.state == .on {
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Schedule is Active" // too text
            alert.informativeText = "This schedule is currently running. Are you sure you want to delete it? Blocking will stop immediately."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: {result in
                if result == .alertFirstButtonReturn{
                    customBlockingScheduleManagerObj.deleteScheduleAt(self.currentFocusModeIndex)
                    addLog(text: "Deleted running schedule: \(schedule.name)")
                    self.closeView()
                }
            })
        } else {
            customBlockingScheduleManagerObj.deleteScheduleAt(currentFocusModeIndex)
            addLog(text: "Deleted schedule: \(schedule.name)")
            closeView()
        }
    }
    
    
    @IBAction func popUpBtnFocusModeClicked(_ sender: Any) {
        if isCreatingNew{
            if popUpBtnFocusMode.indexOfSelectedItem == focusModeDefaultIndex{
                btnEditBlockList.isHidden = true
            }else{
                btnEditBlockList.isHidden = false
            }
        }else{
            btnEditBlockList.isHidden = false
        }
    }
    
    @IBAction func btnEditBlockListClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "open-preferences", metadata: [:])// todo
        addLog(text: "Showing preferences from edit focus mode")
        
        self.presentAsSheet(getFocusPreferencesVcObject()) // no password needed beacause we are already inside settings
        var index = popUpBtnFocusMode.indexOfSelectedItem
        if isCreatingNew{
            index = index - 1
        }
        
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
    }
    
    @IBAction func btnInfoIUseAiClicked(_ sender: Any) {
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
            var strictnessSuperStrictClickedText = "I understand I cannot stop this focus session until it ends. I am committed to avoiding distractions and getting a ton of work done."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                    strictnessSuperStrictClickedText = startingFocusModeInfo.value(forKey: "strictnessSuperStrictClickedText") as? String ?? strictnessSuperStrictClickedText
                }
            }
            
            showTooltip(sender: sliderStrictness, msg: strictnessSuperStrictClickedText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
        showSelectedStrictnessLevel()
    }
}

