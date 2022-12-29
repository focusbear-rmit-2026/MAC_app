//
//  pomodoroPreferencesAdvancedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/06/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class pomodoroPreferencesAdvancedVc: NSViewController {

    @IBOutlet weak var checkBoxSkipMicrobreaks: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    @IBOutlet weak var btnApply: NSButton!
    @IBOutlet weak var checkBoxMonday: NSButton!
    @IBOutlet weak var checkBoxTuesday: NSButton!
    @IBOutlet weak var checkBoxWednesday: NSButton!
    @IBOutlet weak var checkBoxThursday: NSButton!
    @IBOutlet weak var checkBoxFriday: NSButton!
    @IBOutlet weak var checkBoxSaturday: NSButton!
    @IBOutlet weak var checkBoxSunday: NSButton!
    
    @IBOutlet weak var lblSelectDaysForPomodoro: NSTextField!
    @IBOutlet weak var popUpBtnPomodoroCount: NSPopUpButton!
    @IBOutlet weak var lblHowManyPomodoro: NSTextField!
    @IBOutlet weak var lblDescriptionChooseFocusSecond: NSTextField!
    @IBOutlet weak var lblDescriptionChooseFocusFirst: NSTextField!
    
    @IBOutlet weak var popUpBtnFocusModes: NSPopUpButton!
    @IBOutlet weak var lblChooseFocus: NSTextField!
    @IBOutlet weak var lblDescriptionHardcorePomodoro: NSTextField!
    @IBOutlet weak var checkBoxUseHardcorePomodoro: NSButton!
    
    var generalVcObj:generalVc?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        checkBoxSkipMicrobreaks.title = "Skip microbreaks during work blocks?"
        checkBoxUseHardcorePomodoro.title = "Use hardcore pomodoro mode"
        lblDescriptionHardcorePomodoro.stringValue = "(Lock in the focus mode for multiple pomodoros)"
        lblChooseFocus.stringValue = "Choose the focus mode"
        lblDescriptionChooseFocusFirst.stringValue = "You won't be able to change the focus mode until the time is up"
        lblDescriptionChooseFocusSecond.stringValue = "(you still get to use any app/website during the 5 minutes break)"
        lblHowManyPomodoro.stringValue = "How many pomodoros you want to focus for:"
        lblSelectDaysForPomodoro.stringValue = "Schedule specific days you want to run the hardcore pomodoro mode after Morning  Routine:"
        
        checkBoxMonday.title = "Monday"
        checkBoxTuesday.title = "Tuesday"
        checkBoxWednesday.title = "Wednesday"
        checkBoxThursday.title = "Thursday"
        checkBoxFriday.title = "Friday"
        checkBoxSaturday.title = "Saturday"
        checkBoxSunday.title = "Sunday"
        
        
        btnApply.title = "Apply"
        btnCancel.title = buttonCancelText
        
        
        
        
        if let pomodoroPreferencesAdvancedInfo = configjson.value(forKey: "pomodoroPreferencesAdvancedInfo") as? NSDictionary{
            checkBoxUseHardcorePomodoro.title = pomodoroPreferencesAdvancedInfo.value(forKey: "checkBoxUseHardcorePomodoroText") as? String ?? checkBoxUseHardcorePomodoro.title
            lblDescriptionHardcorePomodoro.stringValue = pomodoroPreferencesAdvancedInfo.value(forKey: "descriptionHardcorePomodoroText") as? String ?? lblDescriptionHardcorePomodoro.stringValue
            lblChooseFocus.stringValue = pomodoroPreferencesAdvancedInfo.value(forKey: "chooseFocusText") as? String ?? lblChooseFocus.stringValue
            lblDescriptionChooseFocusFirst.stringValue = pomodoroPreferencesAdvancedInfo.value(forKey: "descriptionChooseFocusFirstText") as? String ?? lblDescriptionChooseFocusFirst.stringValue
            lblDescriptionChooseFocusSecond.stringValue = pomodoroPreferencesAdvancedInfo.value(forKey: "descriptionChooseFocusSecondText") as? String ?? lblDescriptionChooseFocusSecond.stringValue
            lblHowManyPomodoro.stringValue = pomodoroPreferencesAdvancedInfo.value(forKey: "HowManyPomodoroText") as? String ?? lblHowManyPomodoro.stringValue
            lblSelectDaysForPomodoro.stringValue = pomodoroPreferencesAdvancedInfo.value(forKey: "selectDaysForPomodoroText") as? String ?? lblSelectDaysForPomodoro.stringValue
            btnApply.title = pomodoroPreferencesAdvancedInfo.value(forKey: "buttonApplyText") as? String ?? btnApply.title
            checkBoxSkipMicrobreaks.title = pomodoroPreferencesAdvancedInfo.value(forKey: "buttonSkipMicrobreaksText") as? String ?? checkBoxSkipMicrobreaks.title
        }
        
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            checkBoxMonday.title = common.value(forKey: "mondayText") as? String ?? checkBoxMonday.title
            checkBoxTuesday.title = common.value(forKey: "tuesdayText") as? String ?? checkBoxTuesday.title
            checkBoxWednesday.title = common.value(forKey: "wednesdayText") as? String ?? checkBoxWednesday.title
            checkBoxThursday.title = common.value(forKey: "thursdayText") as? String ?? checkBoxThursday.title
            checkBoxFriday.title = common.value(forKey: "fridayText") as? String ?? checkBoxFriday.title
            checkBoxSaturday.title = common.value(forKey: "saturdayText") as? String ?? checkBoxSaturday.title
            checkBoxSunday.title = common.value(forKey: "sundayText") as? String ?? checkBoxSunday.title
        }
        
        popUpBtnPomodoroCount.removeAllItems()
        for i in 2...20{
            popUpBtnPomodoroCount.addItem(withTitle: "\(i)")
        }
    }
    override func viewWillAppear() {

        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        if let isEnabled = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
            if isEnabled{
                checkBoxUseHardcorePomodoro.state = .on
            }else{
                checkBoxUseHardcorePomodoro.state = .off
            }
        }
        var arrDaysHardcorePomodoro = [String]()
        if let arrDays = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroArrDays) as? [String]{
            arrDaysHardcorePomodoro = arrDays
        }else{
            arrDaysHardcorePomodoro = [SettingsManagerObject.kMonday, SettingsManagerObject.kTuesday, SettingsManagerObject.kWednesday, SettingsManagerObject.kThursday, SettingsManagerObject.kFriday, SettingsManagerObject.kSaturday, SettingsManagerObject.kSunday]
            UserDefaults.standard.set(arrDaysHardcorePomodoro, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroArrDays)
        }
        
        
        
        // check box monday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kMonday){
            checkBoxMonday.state = .on
        }else{
            checkBoxMonday.state = .off
        }
        
        
        // check box Tuesday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kTuesday){
            checkBoxTuesday.state = .on
        }else{
            checkBoxTuesday.state = .off
        }
        
        // check box Wednesday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kWednesday){
            checkBoxWednesday.state = .on
        }else{
            checkBoxWednesday.state = .off
        }
        
        // check box Thursday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kThursday){
            checkBoxThursday.state = .on
        }else{
            checkBoxThursday.state = .off
        }
        
        
        // check box Friday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kFriday){
            checkBoxFriday.state = .on
        }else{
            checkBoxFriday.state = .off
        }
        
        // check box Saturday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kSaturday){
            checkBoxSaturday.state = .on
        }else{
            checkBoxSaturday.state = .off
        }
        
        // check box Sunday
        if arrDaysHardcorePomodoro.contains(SettingsManagerObject.kSunday){
            checkBoxSunday.state = .on
        }else{
            checkBoxSunday.state = .off
        }
        
        
        // popup button focus names
        
        popUpBtnFocusModes.removeAllItems()
        var arrAllFocusItems = [String]()
        for i in 0..<arrFocusType.count{
            if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true) && !(arrFocusType[i]["isLockedFocus"] as? Bool ?? false == true){
                if let name = arrFocusType[i]["name"] as? String{
                    popUpBtnFocusModes.addItem(withTitle: name)
                    arrAllFocusItems.append(name)
                }
            }
        }

        
        if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
            if arrAllFocusItems.contains(name){
                popUpBtnFocusModes.selectItem(withTitle: name)
            }else{
                popUpBtnFocusModes.selectItem(withTitle: arrAllFocusItems[0])
                UserDefaults.standard.set(arrAllFocusItems[0], forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName)
                SettingsManagerObject.isSettingsChanged = true
            }
        }else{
            popUpBtnFocusModes.selectItem(withTitle: arrAllFocusItems[0])
            UserDefaults.standard.set(arrAllFocusItems[0], forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName)
        }
        
        
        if let count = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedCount) as? Int{
            popUpBtnPomodoroCount.selectItem(withTitle: "\(count)")
        }else{
            popUpBtnPomodoroCount.selectItem(withTitle: "2")
            UserDefaults.standard.set(2, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedCount)
        }
        
        if let val = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroSkipMicroBreaks) as? Bool{
            if val{
                checkBoxSkipMicrobreaks.state = .on
            }else{
                checkBoxSkipMicrobreaks.state = .off
            }
            
        }else{
            checkBoxSkipMicrobreaks.state = .off
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroSkipMicroBreaks)
        }
        
        
        
        recheckStateAllElements()
    }

    func recheckStateAllElements(){
        if checkBoxUseHardcorePomodoro.state == .on{
            checkBoxMonday.isEnabled = true
            checkBoxTuesday.isEnabled = true
            checkBoxWednesday.isEnabled = true
            checkBoxThursday.isEnabled = true
            checkBoxFriday.isEnabled = true
            checkBoxSaturday.isEnabled = true
            checkBoxSunday.isEnabled = true
            popUpBtnFocusModes.isEnabled = true
            popUpBtnPomodoroCount.isEnabled = true
            checkBoxSkipMicrobreaks.isEnabled = true
        }else{
            checkBoxMonday.isEnabled = false
            checkBoxTuesday.isEnabled = false
            checkBoxWednesday.isEnabled = false
            checkBoxThursday.isEnabled = false
            checkBoxFriday.isEnabled = false
            checkBoxSaturday.isEnabled = false
            checkBoxSunday.isEnabled = false
            popUpBtnFocusModes.isEnabled = false
            popUpBtnPomodoroCount.isEnabled = false
            checkBoxSkipMicrobreaks.isEnabled = false
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        if generalVcObj != nil{// doing this  becuse we do some things in viewwillappear function :- if saved focus mode dose not match to any focus name in the list than we automatically change the selected focus name and save this.
            generalVcObj!.resetPomodoroModeState()
        }
        self.dismiss(self)
    }
    @IBAction func btnApplyClicked(_ sender: Any) {
        if checkBoxUseHardcorePomodoro.state == .on{
            
            if checkBoxMonday.state == .off && checkBoxTuesday.state == .off && checkBoxWednesday.state == .off && checkBoxThursday.state == .off && checkBoxFriday.state == .off && checkBoxSaturday.state == .off && checkBoxSunday.state == .off{
                
                let alert = NSAlert()
                alert.setSharingType()
                alert.alertStyle = .informational
                
                var msgText = "Please select atleast one day."
                if let pomodoroPreferencesAdvancedInfo = configjson.value(forKey: "pomodoroPreferencesAdvancedInfo") as? NSDictionary{
                    msgText = pomodoroPreferencesAdvancedInfo.value(forKey: "selectAtleastOneDayText") as? String ?? msgText
                }

                alert.messageText = msgText
                alert.addButton(withTitle: buttonOkText)

                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                       
                    }
                })
                
                return
            }
            
            var arrDaysHardcorePomodoro = [String]()
            
            // check box monday
            if checkBoxMonday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kMonday)
            }
            
            
            // check box Tuesday
            if checkBoxTuesday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kTuesday)
            }
            
            // check box Wednesday
            if checkBoxWednesday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kWednesday)
            }
            
            // check box Thursday
            if checkBoxThursday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kThursday)
            }
            
            
            // check box Friday
            if checkBoxFriday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kFriday)
            }
            
            // check box Saturday
            if checkBoxSaturday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kSaturday)
            }
            
            // check box Sunday
            if checkBoxSunday.state == .on{
                arrDaysHardcorePomodoro.append(SettingsManagerObject.kSunday)
            }
            UserDefaults.standard.set(arrDaysHardcorePomodoro, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroArrDays)
            
            // popup button focus names
            UserDefaults.standard.set(popUpBtnFocusModes.titleOfSelectedItem, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName)
            
            // popup button Pomodoro Count
            UserDefaults.standard.set(Int(popUpBtnPomodoroCount.titleOfSelectedItem ?? "2") ?? 2, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedCount)

            
            if checkBoxSkipMicrobreaks.state == .on{
                UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroSkipMicroBreaks)
            }else{
                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroSkipMicroBreaks)
            }
            
            
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled)
        }else{
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled)
        }
        
        if generalVcObj != nil{
            generalVcObj!.resetPomodoroModeState()
        }
        SettingsManagerObject.isSettingsChanged = true
        allApiObject.capturePosthog(event: "edit-super-pomodoro-mode-settings", metadata: [:])
        self.dismiss(self)
    }
    @IBAction func checkBoxUseHardcorePomodoroClicked(_ sender: Any) {
        recheckStateAllElements()
    }
    @IBAction func checkBoxSkipMicrobreaksClicked(_ sender: Any) {
    }
}
