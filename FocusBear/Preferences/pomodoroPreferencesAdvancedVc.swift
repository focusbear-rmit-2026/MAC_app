//
//  pomodoroPreferencesAdvancedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/06/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class pomodoroPreferencesAdvancedVc: NSViewController {

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

        if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) as? Bool{
            if isEnabled{
                checkBoxUseHardcorePomodoro.state = .on
            }else{
                checkBoxUseHardcorePomodoro.state = .off
            }
        }
        var arrDaysHardcorePomodoro = [String]()
        if let arrDays = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroArrDays) as? [String]{
            arrDaysHardcorePomodoro = arrDays
        }else{
            arrDaysHardcorePomodoro = [kMonday, kTuesday, kWednesday, kThursday, kFriday, kSaturday, kSunday]
            UserDefaults.standard.set(arrDaysHardcorePomodoro, forKey: kUserdefaultsHardcorePomodoroArrDays)
        }
        
        
        
        // check box monday
        if arrDaysHardcorePomodoro.contains(kMonday){
            checkBoxMonday.state = .on
        }else{
            checkBoxMonday.state = .off
        }
        
        
        // check box Tuesday
        if arrDaysHardcorePomodoro.contains(kTuesday){
            checkBoxTuesday.state = .on
        }else{
            checkBoxTuesday.state = .off
        }
        
        // check box Wednesday
        if arrDaysHardcorePomodoro.contains(kWednesday){
            checkBoxWednesday.state = .on
        }else{
            checkBoxWednesday.state = .off
        }
        
        // check box Thursday
        if arrDaysHardcorePomodoro.contains(kThursday){
            checkBoxThursday.state = .on
        }else{
            checkBoxThursday.state = .off
        }
        
        
        // check box Friday
        if arrDaysHardcorePomodoro.contains(kFriday){
            checkBoxFriday.state = .on
        }else{
            checkBoxFriday.state = .off
        }
        
        // check box Saturday
        if arrDaysHardcorePomodoro.contains(kSaturday){
            checkBoxSaturday.state = .on
        }else{
            checkBoxSaturday.state = .off
        }
        
        // check box Sunday
        if arrDaysHardcorePomodoro.contains(kSunday){
            checkBoxSunday.state = .on
        }else{
            checkBoxSunday.state = .off
        }
        
        
        // popup button focus names
        
        popUpBtnFocusModes.removeAllItems()
        var arrAllFocusItems = [String]()
        for i in 0..<arrFocusType.count{
            if let name = arrFocusType[i]["name"] as? String{
                popUpBtnFocusModes.addItem(withTitle: name)
                arrAllFocusItems.append(name)
            }
        }

        
        if let name = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedName) as? String{
            if arrAllFocusItems.contains(name){
                popUpBtnFocusModes.selectItem(withTitle: name)
            }else{
                popUpBtnFocusModes.selectItem(withTitle: arrAllFocusItems[0])
                UserDefaults.standard.set(arrAllFocusItems[0], forKey: kUserdefaultsHardcorePomodoroFocusedName)
            }
        }else{
            popUpBtnFocusModes.selectItem(withTitle: arrAllFocusItems[0])
            UserDefaults.standard.set(arrAllFocusItems[0], forKey: kUserdefaultsHardcorePomodoroFocusedName)
        }
        
        
        if let count = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedCount) as? Int{
            popUpBtnPomodoroCount.selectItem(withTitle: "\(count)")
        }else{
            popUpBtnPomodoroCount.selectItem(withTitle: "2")
            UserDefaults.standard.set(2, forKey: kUserdefaultsHardcorePomodoroFocusedCount)
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
                if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alert.window.sharingType = .none
                    }
                }
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
                arrDaysHardcorePomodoro.append(kMonday)
            }
            
            
            // check box Tuesday
            if checkBoxTuesday.state == .on{
                arrDaysHardcorePomodoro.append(kTuesday)
            }
            
            // check box Wednesday
            if checkBoxWednesday.state == .on{
                arrDaysHardcorePomodoro.append(kWednesday)
            }
            
            // check box Thursday
            if checkBoxThursday.state == .on{
                arrDaysHardcorePomodoro.append(kThursday)
            }
            
            
            // check box Friday
            if checkBoxFriday.state == .on{
                arrDaysHardcorePomodoro.append(kFriday)
            }
            
            // check box Saturday
            if checkBoxSaturday.state == .on{
                arrDaysHardcorePomodoro.append(kSaturday)
            }
            
            // check box Sunday
            if checkBoxSunday.state == .on{
                arrDaysHardcorePomodoro.append(kSunday)
            }
            UserDefaults.standard.set(arrDaysHardcorePomodoro, forKey: kUserdefaultsHardcorePomodoroArrDays)
            
            // popup button focus names
            UserDefaults.standard.set(popUpBtnFocusModes.titleOfSelectedItem, forKey: kUserdefaultsHardcorePomodoroFocusedName)
            
            // popup button Pomodoro Count
            UserDefaults.standard.set(Int(popUpBtnPomodoroCount.titleOfSelectedItem ?? "2") ?? 2, forKey: kUserdefaultsHardcorePomodoroFocusedCount)

            UserDefaults.standard.set(true, forKey: kUserdefaultsHardcorePomodoroEnabled)
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsHardcorePomodoroEnabled)
        }
        
        if generalVcObj != nil{
            generalVcObj!.resetPomodoroModeState()
        }
        self.dismiss(self)
    }
    @IBAction func checkBoxUseHardcorePomodoroClicked(_ sender: Any) {
        recheckStateAllElements()
    }
}
