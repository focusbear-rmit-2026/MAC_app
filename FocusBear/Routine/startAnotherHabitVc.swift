//
//  startAnotherHabitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class startAnotherHabitVc: NSViewController {

    @IBOutlet weak var heightBox: NSLayoutConstraint!// 510
    @IBOutlet weak var brnClose: cursorButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnStart: Button!
    var currentHabitIndex = 0
    
    var arrFilteredHabits = [habit]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Choose the next habit to do from the following options:"
        btnCancel.title = buttonCancelText
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            lblTitle.stringValue = activityInfo.value(forKey: "titleChooseHabitText") as? String ?? lblTitle.stringValue
        }
    }
    
    override func viewWillAppear() {
        arrFilteredHabits.removeAll()
        if currentState == ._MORNING_HABIT_{
            for i in currentHabitIndex + 1..<arrFilteredMorningHabits.count{
                arrFilteredHabits.append(arrFilteredMorningHabits[i])
            }
        }else if currentState == ._EVENING_HABIT_{
            if isHighPrioritySequenceGoing{
                for i in currentHabitIndex + 1..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].isPriorityHigh{
                        if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                            let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                            let currentDate = Date()
                            if currentDate > cutOffDate{
                                addLog(text: "file startAnotherHabitVc :- func viewWillAppear")// remove this
                                addLog(text: "evening habit ignored:- this habit is high priority habit and cutoff time has passed:- \(arrFilteredEveningHabits[i].name)  \(arrFilteredEveningHabits[i].id)") // remove this
                                continue;
                            }
                        }
                        arrFilteredHabits.append(arrFilteredEveningHabits[i])
                    }
                }
            }else{
                for i in currentHabitIndex + 1..<arrFilteredEveningHabits.count{
                    arrFilteredHabits.append(arrFilteredEveningHabits[i])
                }
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            for i in currentHabitIndex + 1..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                arrFilteredHabits.append(arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i])
            }
        }
        tblView.reloadData()
        if (mainWindowControllerObj?.window?.frame.height ?? 700) < 550{
            heightBox.constant = (mainWindowControllerObj?.window?.frame.height ?? 700) - 60
        }else{
            heightBox.constant = 510
        }
    }
    @IBAction func btnStartClicked(_ sender: Any) {
        if tblView.selectedRow == -1{
            self.dismiss(self)
            return;
        }
        let selectedHabit = arrFilteredHabits[tblView.selectedRow]
        if currentState == ._MORNING_HABIT_{
            for i in 0..<arrFilteredMorningHabits.count{
                let habit = arrFilteredMorningHabits[i]
                if habit.id == selectedHabit.id{
                    arrFilteredMorningHabits.remove(at: i)
                    arrFilteredMorningHabits.insert(habit, at: currentHabitIndex)
                    break;
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            for i in currentHabitIndex + 1..<arrFilteredEveningHabits.count{
                let habit = arrFilteredEveningHabits[i]
                if habit.id == selectedHabit.id{
                    arrFilteredEveningHabits.remove(at: i)
                    arrFilteredEveningHabits.insert(habit, at: currentHabitIndex)
                    break;
                }
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i]
                if habit.id == selectedHabit.id{
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: i)
                    arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: currentHabitIndex)
                    break;
                }
            }
        }
        if currentAction == ._INPROGRESS_{
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: selectedHabit.durationSeconds, name: selectedHabit.name, currentHabit: selectedHabit, currentTimerValue: 0)
        }else{
            if thirdVcObj?.boxBg.isHidden == true{// it means remember next habit is added
                if rememberNextHabitVcObj != nil{
                    if thirdVcObj?.view.subviews.contains(rememberNextHabitVcObj!.view) ?? false{
                        if rememberNextHabitVcObj?.btnStartNextHabit.isHidden == false{
                            rememberNextHabitVcObj?.btnStartNextHabitClicked(self)
                        }
                    }
                }
            }else{
                thirdVcObj?.btnMainClicked(self)
            }
            
        }
        self.dismiss(self)
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        self.dismiss(self)
    }
}
extension startAnotherHabitVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return  arrFilteredHabits.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            cell.boxBg.fillColor = NSColor.clear
            cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredHabits[row].name ?? "")"
            cell.boxBg.borderColor = NSColor.clear
            cell.lblTitle.tag = 99
            if tblView.selectedRow == row{
                cell.boxBg.fillColor = NSColor.systemBlue
                cell.lblTitle.textColor = NSColor.white
            }else{
                cell.lblTitle.textColor = NSColor.labelColor
            }
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblView.selectedRow == -1{
            return;
        }
        for row in 0..<tblView.numberOfRows{
            if let cell = tblView.view(atColumn: 0, row: row, makeIfNecessary: true) as? tblCellHabits{
                cell.boxBg.fillColor = NSColor.clear
                cell.lblTitle.textColor = NSColor.labelColor
            }
        }
        
        if let cell = tblView.view(atColumn: 0, row: tblView.selectedRow, makeIfNecessary: true) as? tblCellHabits{
            cell.boxBg.fillColor = NSColor.systemBlue
            cell.lblTitle.textColor = NSColor.white
        }
        btnStart.title = getstartActivityButtonText(seconds: arrFilteredHabits[tblView.selectedRow].durationSeconds, name: arrFilteredHabits[tblView.selectedRow].name)
    }
}
