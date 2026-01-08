//
//  chooseHabitsVC.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/02/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class chooseHabitsVC: NSViewController {

    @IBOutlet weak var heightBox: NSLayoutConstraint!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var checkBoxSelectAll: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblCompletionTime: NSTextField!
    @IBOutlet weak var lblTitleRequiredTime: NSTextField!
    @IBOutlet weak var lblTitleCompletionTime: NSTextField!
    @IBOutlet weak var lblRequiredTime: NSTextField!
    @IBOutlet weak var brnClose: cursorButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnStart: Button!
    var currentHabitIndex = 0
    var arrSearchedFilteredHabits = [habitInfo]()
    var arrFilteredHabits = [habitInfo]()
    struct habitInfo {
        var habit:habit!
        var state:Bool!
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Choose Habits:"
        btnCancel.title = buttonCancelText
        btnStart.title = "Continue"
        lblTitleRequiredTime.stringValue = "Total time required for the selected habits:"
        lblTitleCompletionTime.stringValue = "Expected completion time:"
        lblSubTitle.stringValue = "Select the habits you want to do in this routine."
        checkBoxSelectAll.title = "Select / Deselect all"
        btnCancel.title = "Completely Skip my morning habits for today"
        
        if let chooseHabitsVCInfo = configjson.value(forKey: "chooseHabitsVCInfo") as? NSDictionary{
            lblTitle.stringValue = chooseHabitsVCInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleRequiredTime.stringValue = chooseHabitsVCInfo.value(forKey: "titleRequiredTime") as? String ?? lblTitleRequiredTime.stringValue
            lblTitleCompletionTime.stringValue = chooseHabitsVCInfo.value(forKey: "titleCompletionTime") as? String ?? lblTitleCompletionTime.stringValue
            btnStart.title = chooseHabitsVCInfo.value(forKey: "buttonContinueText") as? String ?? btnStart.title
            lblSubTitle.stringValue = chooseHabitsVCInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            checkBoxSelectAll.title = chooseHabitsVCInfo.value(forKey: "checkBoxSelectAllText") as? String ?? checkBoxSelectAll.title
        }
        searchField.delegate = self
    }
    
    func isActivityCompleted(id:String, habits:[habit])->Bool{
        if currentHabitIndex == -1{
            return false
        }
        for i in 0..<currentHabitIndex + 1{
            let habit = habits[i]
            if habit.id == id{
                return true
            }
        }
        return false
    }
    
    override func viewWillAppear() {
        btnCancel.isHidden = false
        searchField.stringValue = ""
        arrSearchedFilteredHabits.removeAll()
        arrFilteredHabits.removeAll()
        if currentState == ._MORNING_HABIT_{
            btnCancel.title = "Completely Skip my morning habits for today"
            if let chooseHabitsVCInfo = configjson.value(forKey: "chooseHabitsVCInfo") as? NSDictionary{
                btnCancel.title = chooseHabitsVCInfo.value(forKey: "buttonSkipMorningHabitsText") as? String ?? btnCancel.title
            }
            for i in 0..<arrPreFilteredMorningHabits.count{
                let id = arrPreFilteredMorningHabits[i].id ?? ""
                let isActivityCompleted = isActivityCompleted(id: id, habits: arrFilteredMorningHabits)
                if !isActivityCompleted{
                    var isAdded = false
                    for habit in arrFilteredMorningHabits{
                        if habit.id == id{
                             isAdded = true
                            break;
                        }
                    }
                    if isAdded{
                        arrFilteredHabits.append(habitInfo(habit: arrPreFilteredMorningHabits[i], state: true))
                    }else{
                        arrFilteredHabits.append(habitInfo(habit: arrPreFilteredMorningHabits[i], state: false))
                    }
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            btnCancel.title = "Completely Skip my evening habits for today"
            if let chooseHabitsVCInfo = configjson.value(forKey: "chooseHabitsVCInfo") as? NSDictionary{
                btnCancel.title = chooseHabitsVCInfo.value(forKey: "buttonSkipEveningHabitsText") as? String ?? btnCancel.title
            }
            for i in 0..<arrPreFilteredEveningHabits.count{
                if isHighPrioritySequenceGoing{
                    if !arrPreFilteredEveningHabits[i].isPriorityHigh{
                        continue;
                    }else {
                        if let cutOffTime = arrPreFilteredEveningHabits[i].cutOffTime{
                            let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                            let currentDate = Date()
                            if currentDate > cutOffDate{
                                addLog(text: "file chooseHabitsVC :- func viewWillAppear")// remove this
                                addLog(text: "evening habit ignored:- this habit is high priority habit and cutoff time has passed:- \(arrPreFilteredEveningHabits[i].name)  \(arrPreFilteredEveningHabits[i].id)") // remove this
                                continue;
                            }
                        }
                    }
                }
                
                
                
                let id = arrPreFilteredEveningHabits[i].id ?? ""
                let isActivityCompleted = isActivityCompleted(id: id, habits: arrFilteredEveningHabits)
                if !isActivityCompleted{
                    var isAdded = false
                    for habit in arrFilteredEveningHabits{
                        if habit.id == id{
                            isAdded = true
                            break;
                        }
                    }
                    if isAdded{
                        arrFilteredHabits.append(habitInfo(habit: arrPreFilteredEveningHabits[i], state: true))
                    }else{
                        arrFilteredHabits.append(habitInfo(habit: arrPreFilteredEveningHabits[i], state: false))
                    }
                }
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            btnCancel.isHidden = true
            for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits.count{
                let id = arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits[i].id ?? ""
                let isActivityCompleted = isActivityCompleted(id: id, habits: arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits)
                if !isActivityCompleted{
                    var isAdded = false
                    for habit in arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits{
                        if habit.id == id{
                            isAdded = true
                            break;
                        }
                    }
                    if isAdded{
                        arrFilteredHabits.append(habitInfo(habit: arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits[i], state: true))
                    }else{
                        arrFilteredHabits.append(habitInfo(habit: arrAllCustomRoutine[currentRoutineIndex].arrAllPreFilterHabits[i], state: false))
                    }
                }
            }
        }

        tblView.reloadData()
        checkTotalDuration()
        
        if (mainWindowControllerObj?.window?.frame.height ?? 700) < 600{
            heightBox.constant = (mainWindowControllerObj?.window?.frame.height ?? 700) - 60
        }else{
            heightBox.constant = 569
        }
    }
    
    func checkButtonState(){
        var isAnyItemSelected = false
        for info in arrFilteredHabits{
            if info.state{
                isAnyItemSelected = true
                btnStart.isEnabled = true
                break;
            }
        }
        if !isAnyItemSelected{
            btnStart.isEnabled = false
        }
    }
    
    func checkTotalDuration(){
        var totalDuration = 0
        for habitInfo in arrFilteredHabits{
            if habitInfo.habit.useTimer && habitInfo.state{
                totalDuration += habitInfo.habit.durationSeconds
            }
        }
        
        let date = Date().addingTimeInterval(TimeInterval(totalDuration))
        
        lblRequiredTime.stringValue = getStringTime(seconds: totalDuration)
        lblCompletionTime.stringValue = getStringFromDate(date: date, dateFormat: "hh:mm a")
        if totalDuration == 0{
            lblCompletionTime.isHidden = true
            lblTitleCompletionTime.isHidden = true
        }else{
            lblCompletionTime.isHidden = false
            lblTitleCompletionTime.isHidden = false
        }
    }
    
    @IBAction func btnStartClicked(_ sender: Any) {
        let sequenceId = arrFilteredHabits[0].habit.activity_sequence_id ?? ""
        var arrHabitIds = [String]()
        
        if currentState == ._MORNING_HABIT_{
            let arrTempFilteredMorningHabits = arrFilteredMorningHabits
            arrFilteredMorningHabits.removeAll()
            
            // add habits which are completed
            if currentHabitIndex != -1{
                for i in 0..<currentHabitIndex + 1{
                    let habit = arrTempFilteredMorningHabits[i]
                    arrFilteredMorningHabits.append(habit)
                }
            }
            //
            for i in 0..<arrFilteredHabits.count{
                if arrFilteredHabits[i].state{
                    arrHabitIds.append(arrFilteredHabits[i].habit.id)
                    arrFilteredMorningHabits.append(arrFilteredHabits[i].habit)
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            let arrTempFilteredEveningHabits = arrFilteredEveningHabits
            arrFilteredEveningHabits.removeAll()
            
            // add habits which are completed
            if currentHabitIndex != -1{
                for i in 0..<currentHabitIndex + 1{
                    let habit = arrTempFilteredEveningHabits[i]
                    arrFilteredEveningHabits.append(habit)
                }
            }
            //
            
            
            for i in 0..<arrFilteredHabits.count{
                if arrFilteredHabits[i].state{
                    arrHabitIds.append(arrFilteredHabits[i].habit.id)
                    arrFilteredEveningHabits.append(arrFilteredHabits[i].habit)
                }else{
                    addLog(text: "habit skipped:- habit was not selected by user this time:- \(arrFilteredHabits[i].habit.name)  \(arrFilteredHabits[i].habit.id)") // remove this
                }
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            let arrTempFilteredHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
            arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.removeAll()
            
            // add habits which are completed
            if currentHabitIndex != -1{
                for i in 0..<currentHabitIndex + 1{
                    let habit = arrTempFilteredHabits[i]
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.append(habit)
                }
            }
            //
            for i in 0..<arrFilteredHabits.count{
                if arrFilteredHabits[i].state{
                    arrHabitIds.append(arrFilteredHabits[i].habit.id)
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.append(arrFilteredHabits[i].habit)
                }
            }
        }
        
        if currentAction == ._START_{
            firstViewControllerObj?.tblViewHabits.reloadData()
        }else if currentAction == ._END_{
            if currentState == ._MORNING_HABIT_ {
                let time = arrFilteredMorningHabits[currentHabitIndex+1].durationSeconds
                if thirdVcObj?.boxBg.isHidden == true{// it means remember next habit is added
                    if rememberNextHabitVcObj != nil{
                        if thirdVcObj?.view.subviews.contains(rememberNextHabitVcObj!.view) ?? false{
                            rememberNextHabitVcObj?.btnStartNextHabit.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[currentHabitIndex+1].name!)
                        }
                    }
                }
                thirdVcObj?.btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[currentHabitIndex+1].name!)
                thirdVcObj?.setProgress()
            }else if currentState == ._EVENING_HABIT_{
                let time = arrFilteredEveningHabits[currentHabitIndex+1].durationSeconds
                if thirdVcObj?.boxBg.isHidden == true{
                    if rememberNextHabitVcObj != nil{
                        if thirdVcObj?.view.subviews.contains(rememberNextHabitVcObj!.view) ?? false{
                            rememberNextHabitVcObj?.btnStartNextHabit.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[currentHabitIndex+1].name!)
                        }
                    }
                }
                thirdVcObj?.btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[currentHabitIndex+1].name!)
                thirdVcObj?.setProgress()
            }else if currentState == ._CUSTOM_ROUTINE_{
                let time = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[currentHabitIndex+1].durationSeconds
                thirdVcObj?.btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[currentHabitIndex+1].name!)
                thirdVcObj?.setProgress()
            }
        }
        

        

        if currentState == ._MORNING_HABIT_{
            let infoDic:[String:Any] = ["sequenceId":sequenceId, "arrHabitIds":arrHabitIds, "date":Date()]
            UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequenceSelectHabitsInfo)
        }else if currentState == ._EVENING_HABIT_{
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? Date()
                let infoDic:[String:Any] = ["sequenceId":sequenceId, "arrHabitIds":arrHabitIds, "date":startDate]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequenceSelectHabitsInfo)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                let infoDic:[String:Any] = ["sequenceId":sequenceId, "arrHabitIds":arrHabitIds, "date":startDate]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequenceSelectHabitsInfo)
            }
            
        }
        self.dismiss(self)
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!

        var sequenceId = ""
        if currentState == ._MORNING_HABIT_{// no need to force complete in morning routine
            sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastHabitShowDate)
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-from":"chooseHabits"])
        }else if currentState == ._FOCUS_SUMMARY_ || currentState == ._EVENING_HABIT_{
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            sequenceId = arrFilteredEveningHabits.first?.activity_sequence_id ?? ""
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-from":"chooseHabits"])
        }
        
        allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
            print("forceCompleteCurrentSequence success")
        })
        
        
        self.dismiss(self)
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        isHabitAlreadyShowed = true
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        currentState = ._NOTHING_
        getHabitsVcObject().setActivityTimer()
        addLog(text: "morning habit skipped by user")
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func checkBoxSelectAllClicked(_ sender: Any) {
        var newState = false
        if checkBoxSelectAll.state == .on{
            newState = true
        }
        if !searchField.stringValue.isEmpty{
            var arrHabitIdsToChange = [String]()
            for i in 0..<arrSearchedFilteredHabits.count{
                arrSearchedFilteredHabits[i].state = newState
                let id = arrSearchedFilteredHabits[i].habit.id ?? ""
                arrHabitIdsToChange.append(id)
            }
            
            for i in 0..<arrFilteredHabits.count{
                if arrHabitIdsToChange.contains(arrFilteredHabits[i].habit.id){
                    arrFilteredHabits[i].state = newState
                }
            }
        }else{
            for i in 0..<arrFilteredHabits.count{
                arrFilteredHabits[i].state = newState
            }
        }
        tblView.reloadData()
        
        checkButtonState()
        checkTotalDuration() 
    }
}

extension chooseHabitsVC: NSSearchFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        print("controlTextDidChange")
        if let searchfield = obj.object as? NSSearchField{
            if self.searchField == searchfield{
                arrSearchedFilteredHabits.removeAll()
                for habit in arrFilteredHabits{
                    if habit.habit.name.localizedStandardContains(searchfield.stringValue){
                        arrSearchedFilteredHabits.append(habit)
                    }
                }
                tblView.reloadData()
            }
        }
    }
}

extension chooseHabitsVC:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if !searchField.stringValue.isEmpty{
            return arrSearchedFilteredHabits.count
        }
        return  arrFilteredHabits.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            cell.checkBox.tag = 99
            
            if !searchField.stringValue.isEmpty{
                cell.checkBox.title = "\(row + 1).   \(arrSearchedFilteredHabits[row].habit.name ?? "")"
                if arrSearchedFilteredHabits[row].state{
                    cell.checkBox.state = .on
                }else{
                    cell.checkBox.state = .off
                }
            }else{
                cell.checkBox.title = "\(row + 1).   \(arrFilteredHabits[row].habit.name ?? "")"
                if arrFilteredHabits[row].state{
                    cell.checkBox.state = .on
                }else{
                    cell.checkBox.state = .off
                }
            }
            
            
            cell.checkBox.target = self
            cell.checkBox.tag = row
            cell.checkBox.action = #selector(checkBoxClicked(sender:))
            return cell
        }
        
        return NSTableCellView()
    }
    
    @objc func checkBoxClicked(sender:NSButton){
        if !searchField.stringValue.isEmpty{
            if arrSearchedFilteredHabits[sender.tag].state{
                arrSearchedFilteredHabits[sender.tag].state = false
            }else{
                arrSearchedFilteredHabits[sender.tag].state = true
            }
            let id = arrSearchedFilteredHabits[sender.tag].habit.id
            for i in 0..<arrFilteredHabits.count{
                if arrFilteredHabits[i].habit.id == id{
                    arrFilteredHabits[i].state = arrSearchedFilteredHabits[sender.tag].state
                    break;
                }
            }
        }else{
            if arrFilteredHabits[sender.tag].state{
                arrFilteredHabits[sender.tag].state = false
            }else{
                arrFilteredHabits[sender.tag].state = true
            }
        }
        tblView.reloadData()
        
        checkButtonState()
        checkTotalDuration()
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblView.selectedRow == -1{
            return;
        }
    }
}
