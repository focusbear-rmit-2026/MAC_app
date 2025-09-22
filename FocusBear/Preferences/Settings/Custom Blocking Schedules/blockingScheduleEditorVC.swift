//
//  blockingScheduleEditorVC.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class blockingScheduleEditorVC: NSViewController {
    
    @IBOutlet weak var btnEditBlockList: underLineButton!
    @IBOutlet weak var popUpBtnFocusMode: NSPopUpButton!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var boxBlockingModes: NSBox!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnDelete: Button!
    @IBOutlet weak var btnSave: Button!
    
    @IBOutlet weak var btnCoolDownBlock: mouseDownEffectButton!
    @IBOutlet weak var btnGentleBlock: mouseDownEffectButton!
    @IBOutlet weak var btnStrictBlock: mouseDownEffectButton!
    
    @IBOutlet weak var boxSmallCircleCoolDownBlock: NSBox!
    @IBOutlet weak var boxBigCircleCoolDownBlock: NSBox!
    @IBOutlet weak var imgViewCoolDownBlock: NSImageView!
    @IBOutlet weak var lblDescriptionCoolDownBlock: NSTextField!
    @IBOutlet weak var lblTitleCoolDownBlock: NSTextField!
    @IBOutlet weak var boxCoolDownBlock: NSBox!
    
    @IBOutlet weak var boxSmallCircleGentleBlock: NSBox!
    @IBOutlet weak var boxBigCircleGentleBlock: NSBox!
    @IBOutlet weak var imgViewGentleBlock: NSImageView!
    @IBOutlet weak var lblDescriptionGentleBlock: NSTextField!
    @IBOutlet weak var lblTitleGentleBlock: NSTextField!
    @IBOutlet weak var boxGentleBlock: NSBox!
    
    @IBOutlet weak var boxSmallCircleStrictBlock: NSBox!
    @IBOutlet weak var boxBigCircleStrictBlock: NSBox!
    @IBOutlet weak var imgViewStrictBlock: NSImageView!
    @IBOutlet weak var lblDescriptionStrictBlock: NSTextField!
    @IBOutlet weak var lblTitleStrictBlock: NSTextField!
    @IBOutlet weak var boxStrictBlock: NSBox!
    
    @IBOutlet weak var lblTitleBlockMode: NSTextField!
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
    
    
    var blockMode:BlockLevel = .gentle
    var arrAllWeekDayBox = [toggleTitledBox]()
    var focusModeDefaultIndex = 0
    var arrFocusTypeForBlockingSchedule = [[String : Any]]()
    var isCreatingNew = false
    var currentFocusModeIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

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
        
        boxStrictBlock.wantsLayer = true
        boxStrictBlock.layer?.cornerRadius = 8
        
        boxCoolDownBlock.wantsLayer = true
        boxCoolDownBlock.layer?.cornerRadius = 8
        
        boxGentleBlock.wantsLayer = true
        boxGentleBlock.layer?.cornerRadius = 8
        
        
        imgViewStrictBlock.image = NSImage(imageLiteralResourceName: NSImage.lockLockedTemplateName)
        
        if #available(macOS 11.0, *) {
            imgViewCoolDownBlock.image = NSImage(systemSymbolName: "pause", accessibilityDescription: nil)
        } else {
            imgViewCoolDownBlock.image = NSImage(imageLiteralResourceName: NSImage.touchBarPauseTemplateName)
        }

        if #available(macOS 11.0, *) {
            imgViewGentleBlock.image = NSImage(systemSymbolName: "hand.raised.palm.facing", accessibilityDescription: nil)
        } else {
            imgViewGentleBlock.image = NSImage(imageLiteralResourceName: NSImage.lockUnlockedTemplateName)
        }
        
        btnEditBlockList.title = "Edit block list"
    }
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here
        btnSave.title = btnSave.title
        btnCancel.title = btnCancel.title
        btnDelete.title = btnDelete.title
    }
    
    func reloadFocusModeList(){
        var selectedIndex = popUpBtnFocusMode.indexOfSelectedItem
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
//    override func viewDidLayout() {
//        super.viewDidLayout()
//        scrollView.documentView?.setNeedsDisplay(scrollView.documentView!.bounds)
//    }
    // Block list // todo 
//        “Choose a Focus Mode to manage your blocked list”
    // Edit block liost
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
            blockMode = .gentle
        }else{
            textFieldScheduleName.stringValue = arrBlockingSchedule[index].name
            let weekDays = arrBlockingSchedule[index].daysOfWeek
            for box in arrAllWeekDayBox{
                if weekDays.contains(box.index){
                    box.isSelected = true
                }
            }
            blockMode = arrBlockingSchedule[index].blockLevel
            
            
            popUpBtnFocusMode.removeAllItems()
            for i in 0..<arrFocusTypeForBlockingSchedule.count{
                if let name = arrFocusTypeForBlockingSchedule[i]["name"] as? String{
                    popUpBtnFocusMode.addItem(withTitle: name)
                }
            }
            
            
            let focusModeId = arrBlockingSchedule[index].focusModeID
            
            for i in 0..<arrFocusTypeForBlockingSchedule.count{
                if let id = arrFocusTypeForBlockingSchedule[i]["id"] as? String{
                    if id == focusModeId{
                        popUpBtnFocusMode.selectItem(at: i)
                        break;
                    }
                }
            }
            btnEditBlockList.isHidden = false
            
        }
        resetBlockModeUi()
    }
    
    override func viewWillAppear() {
        resetBlockModeUi()
    }
    
    func resetBlockModeUi(){
        boxBigCircleStrictBlock.borderColor = NSColor.labelColor
        boxBigCircleGentleBlock.borderColor = NSColor.labelColor
        boxBigCircleCoolDownBlock.borderColor = NSColor.labelColor
        
        boxSmallCircleStrictBlock.isHidden = true
        boxSmallCircleCoolDownBlock.isHidden = true
        boxSmallCircleGentleBlock.isHidden = true
        
        imgViewGentleBlock.contentTintColor = nil
        imgViewStrictBlock.contentTintColor = nil
        imgViewCoolDownBlock.contentTintColor = nil
        
        lblTitleStrictBlock.textColor = .labelColor
        lblTitleCoolDownBlock.textColor = .labelColor
        lblTitleGentleBlock.textColor = .labelColor
        
        switch blockMode{
        case .strict:
            imgViewStrictBlock.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxBigCircleStrictBlock.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            lblTitleStrictBlock.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxSmallCircleStrictBlock.isHidden = false
        case .coolDown:
            imgViewCoolDownBlock.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxBigCircleCoolDownBlock.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            lblTitleCoolDownBlock.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxSmallCircleCoolDownBlock.isHidden = false
        case .gentle:
            imgViewGentleBlock.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxBigCircleGentleBlock.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            lblTitleGentleBlock.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxSmallCircleGentleBlock.isHidden = false
        }
    }
    
    func closeView(){
        tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        closeView()
    }
    
    @IBAction func btnGentleBlockClicked(_ sender: Any) {
        blockMode = .gentle
        resetBlockModeUi()
    }
    
    @IBAction func btnStrictBlockClicked(_ sender: Any) {
        blockMode = .strict
        resetBlockModeUi()
    }
    
    @IBAction func btnCoolDownBlockClicked(_ sender: Any) {
        blockMode = .coolDown
        resetBlockModeUi()
    }
    
    @IBAction func btnSaveClicked(_ sender: Any) {
        if textFieldScheduleName.stringValue.isEmpty{
//            show alert todo
            
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Please enter a name for your custom schedule before saving." // todo text
            
//            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
//                    alert.messageText = focusCompletedInfo.value(forKey: "settingNotAvailableText") as? String ?? alert.messageText
//                }
//            }
            
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
                
                
            })
            return;
        }
        
        var arrDays = [Int]()
        
        for box in arrAllWeekDayBox{
            if box.isSelected{
                arrDays.append(box.index)
            }
        }
        
        let focusModeId = arrFocusTypeForBlockingSchedule[popUpBtnFocusMode.indexOfSelectedItem]["id"] as? String ?? ""

        
        let blockingSchedule = customBlockingSchedule(
            name: textFieldScheduleName.stringValue,
            start: getTimeString(date: datePickerFrom.dateValue),
            end: getTimeString(date: datePickerTill.dateValue),
            daysOfWeek: arrDays,
            focusModeID: focusModeId,
            pauseFriction: .timer,
            blockLevel: blockMode,
            isAIBlockingEnabled: true // todo iska button kha aayga
        )
        if isCreatingNew{
            // Create a new schedule
            arrBlockingSchedule.append(blockingSchedule)
        }else{
            arrBlockingSchedule[currentFocusModeIndex] = blockingSchedule
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
        closeView()
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
        
        if let focusModeId = arrFocusTypeForBlockingSchedule[popUpBtnFocusMode.indexOfSelectedItem]["id"] as? String{
            getFocusPreferencesVcObject().selectFocusModeWithId(id: focusModeId)
        }
        getFocusPreferencesVcObject().btnBackToCustomBlocking.isHidden = false
    }
}

