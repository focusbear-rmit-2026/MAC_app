//
//  popUpAddNewFocusGoalVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 24/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class popUpAddNewFocusGoalVc: NSViewController {


    @IBOutlet weak var lblPreviousTask: NSTextField!
    @IBOutlet weak var lblTitlePreviousTask: NSTextField!
    @IBOutlet weak var stackViewPreviousTask: NSStackView!
    @IBOutlet weak var checkBoxMarkCurrentTaskAsCompleted: NSButton!
    @IBOutlet weak var boxMarkCurrentTaskAsComplete: NSBox!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var lblGettingTasks: NSTextField!
    @IBOutlet weak var lblTitleCurrentTask: NSTextField!
    @IBOutlet weak var lblTitleFocusGoal: NSTextField!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet weak var comboBoxTask: searchableComboBox!
    @IBOutlet weak var btnSave: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var arrAllTasks = [NSDictionary]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        checkBoxMarkCurrentTaskAsCompleted.title = "Mark the previous task as complete"
        lblTitle.stringValue = "What's your new focus goal?"
        lblTitleFocusGoal.stringValue = "Focus Goal:"
        lblTitleCurrentTask.stringValue = "New task:"
        lblTitlePreviousTask.stringValue = "Previous task:"
        
        btnSave.title = "Save"
        lblGettingTasks.stringValue = "Fetching tasks..."
        comboBoxTask.customDelegate = self
        comboBoxTask.stringValue = ""
        
        comboBoxTask.items.removeAll()
        arrAllTasks.removeAll()
        comboBoxTask.reloadData()
        lblGettingTasks.isHidden = true
        
        if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
            lblTitle.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleFocusGoal.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "titleGoal") as? String ?? lblTitleFocusGoal.stringValue
            lblTitleCurrentTask.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "titleNewTask") as? String ?? lblTitleCurrentTask.stringValue
            btnSave.title = popUpAddNewFocusGoalVcInfo.value(forKey: "buttonSaveText") as? String ?? btnSave.title
            lblGettingTasks.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "fetchingTaskText") as? String ?? lblGettingTasks.stringValue
            lblTitlePreviousTask.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "titlePreviousTask") as? String ?? lblTitlePreviousTask.stringValue
            checkBoxMarkCurrentTaskAsCompleted.title = popUpAddNewFocusGoalVcInfo.value(forKey: "buttonMarkCurrentTaskAsCompleted") as? String ?? checkBoxMarkCurrentTaskAsCompleted.title
        }
    }
    
    func resetData(intention:String, task:String?){
        textViewIntention.string = intention
        comboBoxTask.isEnabled = false
        comboBoxTask.stringValue = ""
        lblGettingTasks.isHidden = false
        comboBoxTask.items.removeAll()
        arrAllTasks.removeAll()
        loader.startAnimation(self)
        lblGettingTasks.stringValue = "Fetching tasks..."
        if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
            lblGettingTasks.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "fetchingTaskText") as? String ?? lblGettingTasks.stringValue
        }
        
        allApiObject.getAllTasks(completionHandler: {json in
            DispatchQueue.main.async { [self] in
                comboBoxTask.isEnabled = true
                lblGettingTasks.isHidden = true
                print("got all taks")
                if let json = json{
                    arrAllTasks = json
                    for task in json{
                        let title = task.value(forKey: "title") as? String ?? ""
                        comboBoxTask.items.append(title)
                        print(title)
                    }
                }
                comboBoxTask.reloadData()
                loader.stopAnimation(self)
            }
        })
        if let task = getCurrentTaskInFocusMode(){
            lblPreviousTask.stringValue = task
            boxMarkCurrentTaskAsComplete.isHidden = false
            stackViewPreviousTask.isHidden = false
        }else{
            boxMarkCurrentTaskAsComplete.isHidden = true
            stackViewPreviousTask.isHidden = true
        }
        checkBoxMarkCurrentTaskAsCompleted.state = .off
    }
    
    @IBAction func btnSaveClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpAddNewFocusGoalVc:- btnSaveClicked")
        updateFocusModeIntention(intention: textViewIntention.string)
        if taskPlayerWcObj != nil{
            if taskPlayerWcObj?.window?.isVisible ?? false{
                taskPlayerVcObj?.updateIntentionToPlayer()
            }
        }
        let currentTask = comboBoxTask.stringValue.lowercased()
        var taskAlreadyAdded = false
        var taskAddedIndex = 0
        if !currentTask.isEmpty{
            for i in 0..<arrAllTasks.count{
                let task = arrAllTasks[i]
                let taskName = task.value(forKey: "title") as? String ?? ""
                if taskName.lowercased() == currentTask{
                    taskAlreadyAdded = true
                    taskAddedIndex = i
                    break;
                }
            }
            
            if !taskAlreadyAdded{
                lblGettingTasks.stringValue = "Saving task..."
                if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
                    lblGettingTasks.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "SavingTaskText") as? String ?? lblGettingTasks.stringValue
                }
                lblGettingTasks.isHidden = false
                loader.startAnimation(self)
                let today = Date()
                let taskName = comboBoxTask.stringValue
                let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
                let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                allApiObject.addTask(title: taskName, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result,json in
                    if result{
                        
                    }
                    DispatchQueue.main.async { [self] in
                        lblGettingTasks.isHidden = true
                        loader.stopAnimation(self)
                        closeView()
                        if let json = json{
                            if let id = json.value(forKey: "id") as? String{
                                taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskName, id: id, duration: 600, shouldCompleteCurrentTask: checkBoxMarkCurrentTaskAsCompleted.state == .on)
                            }
                        }
                    }
                })
            }else{
                closeView()
                let task = arrAllTasks[taskAddedIndex]
                if let id = task.value(forKey: "id") as? String, let taskTitle = task.value(forKey: "title") as? String{
                    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: checkBoxMarkCurrentTaskAsCompleted.state == .on)
                }
            }
        }else{
            closeView()
        }
        
        
        
    }
    
    func closeView(){
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.closeWindowNeedToCheckAppUrlAgain()
    }
    
    @IBAction func checkBoxMarkCurrentTaskAsCompletedClicked(_ sender: Any) {
        
    }
}

extension popUpAddNewFocusGoalVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if comboBox.stringValue.isEmpty{
            return;
        }

    }
}
