//
//  popUpFocusGoalConfirmationVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 24/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class popUpFocusGoalConfirmationVc: NSViewController {

    @IBOutlet weak var boxNoTaskSpecified: NSBox!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var comboBoxSelectTask: searchableComboBox!
    @IBOutlet weak var lblSelectTask: NSTextField!
    @IBOutlet weak var btnNoCurrentTaskAdded: Button!
    @IBOutlet weak var btnYesRelevant: Button!
    @IBOutlet weak var btnWorkingOnAnotherGoal: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    var arrAllTasks = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnNoCurrentTaskAdded.isSecondaryButton = true
        btnNoCurrentTaskAdded.title = "Set Task"
        lblSelectTask.stringValue = "No current task, select a task to proceed."
        
        
        lblTitle.stringValue = "Are you still working on \"<TASK>\" as part of your focus goal: \"<GOAL>\"?"
        btnWorkingOnAnotherGoal.title = "No I'm working on something else now"
        btnYesRelevant.title = "Yes and this site is relevant"
        
        if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
            lblTitle.stringValue = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoalAndTask") as? String ?? lblTitle.stringValue
            btnWorkingOnAnotherGoal.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonWorkingSomethingElseText") as? String ?? btnWorkingOnAnotherGoal.title
            btnYesRelevant.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonAppRelevantText") as? String ?? btnYesRelevant.title
            btnNoCurrentTaskAdded.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonSetTask") as? String ?? btnNoCurrentTaskAdded.title
            lblSelectTask.stringValue = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleSelectTask") as? String ?? lblSelectTask.stringValue
        }
        
        btnWorkingOnAnotherGoal.isSecondaryButton = true
        
        comboBoxSelectTask.customDelegate = self
        comboBoxSelectTask.stringValue = ""
        
        comboBoxSelectTask.items.removeAll()
        arrAllTasks.removeAll()
        comboBoxSelectTask.reloadData()
        
    }
    
    func resetData(goal:String, task:String?, isApp:Bool){
        arrAllTasks.removeAll()
        
        
        if let task = task{
            var title = "Are you still working on \"<TASK>\" as part of your focus goal: \"<GOAL>\"?"
            if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                title = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoalAndTask") as? String ?? title
            }
            title = title.replacingOccurrences(of: "<TASK>", with: task)
            title = title.replacingOccurrences(of: "<GOAL>", with: goal)
            lblTitle.stringValue = title

            boxNoTaskSpecified.isHidden = true
            btnYesRelevant.isHidden = false
        }else{
            var title = "Is your focus goal still: \"<GOAL>\"?"
            if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                title = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoal") as? String ?? title
            }
            title = title.replacingOccurrences(of: "<GOAL>", with: goal)
            lblTitle.stringValue = title
            boxNoTaskSpecified.isHidden = false
            btnYesRelevant.isHidden = true
            comboBoxSelectTask.setFocus()
            comboBoxSelectTask.isEnabled = false
            comboBoxSelectTask.stringValue = ""
            comboBoxSelectTask.items.removeAll()
            
            loader.startAnimation(self)
            
            allApiObject.getAllTasks(completionHandler: {json in
                DispatchQueue.main.async { [self] in
                    comboBoxSelectTask.isEnabled = true
                   
                    if let json = json{
                        
                        // Remove completed tasks. added in v3.32.487
                        let filteredTasks = json.filter { task in
                            let status = task.value(forKey: "status") as? String ?? ""
                            return status.uppercased() != "COMPLETED"
                        }
                        
                        let sortedTasks = filteredTasks.sorted { t1, t2 in
                            let s1 = t1.value(forKey: "created_at") as? String ?? ""
                            let s2 = t2.value(forKey: "created_at") as? String ?? ""
                            
                            let d1 = getDateFromStringInUtc(dateString: s1) ?? Date.distantPast
                            let d2 = getDateFromStringInUtc(dateString: s2) ?? Date.distantPast
                            
                            return d1 > d2
                        }
                        arrAllTasks = sortedTasks
                        for task in arrAllTasks{
                            let title = task.value(forKey: "title") as? String ?? ""
                            comboBoxSelectTask.items.append(title)
                            print(title)
                        }
                        func getDateFromStringInUtc(dateString: String) -> Date? {
                            let df = DateFormatter()
                            df.locale = Locale(identifier: "en_US_POSIX")
                            df.timeZone = TimeZone(secondsFromGMT: 0)
                            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" // matches your examples
                            return df.date(from: dateString)
                        }
                    }
                    comboBoxSelectTask.reloadData()
                    loader.stopAnimation(self)
                    comboBoxSelectTask.setFocus()
                }
            })
            
        }
        
        if isApp{
            btnYesRelevant.title = "Yes and this app is relevant"
            if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                btnYesRelevant.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonAppRelevantText") as? String ?? btnYesRelevant.title
            }
            
        }else{
            btnYesRelevant.title = "Yes and this site is relevant"
            if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                btnYesRelevant.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonSiteRelevantText") as? String ?? btnYesRelevant.title
            }
            
        }
    }
    
    @IBAction func btnWorkingOnAnotherGoalClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpFocusGoalConfirmationVc:- btnWorkingOnAnotherGoalClicked")
        self.view.removeFromSuperview()
        if arrAllTasks.count == 0{
            popUpBlockConfirmVcObj?.showoPopUpAddNewFocusGoalView()
        }else{
            popUpBlockConfirmVcObj?.showoPopUpAddNewFocusGoalView(arrAllTasks: arrAllTasks)
        }
    }
    
    @IBAction func btnYesRelevantClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpFocusGoalConfirmationVc:- YesRelevantClicked")
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.showConvincedAiPopUpBox(allowedByConvinceAiAlready:false, reason: "")
    }
    
    @IBAction func btnNoCurrentTaskAddedClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpFocusGoalConfirmationVc:- btnSaveClicked")
        
        taskPlayerVcObj?.updateIntentionToPlayer()
        
        let currentTask = comboBoxSelectTask.stringValue.lowercased()
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
                //lblGettingTasks.isHidden = false
                loader.startAnimation(self)
                let today = Date()
                let taskName = comboBoxSelectTask.stringValue
                let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
                let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                addLog(text: "Create new task:- name: \(taskName)")
                allApiObject.addTask(title: taskName, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result,json in
                    if result{
                        addLog(text: "\(taskName) task created successfully.")
                    }
                    DispatchQueue.main.async { [self] in
                        loader.stopAnimation(self)
                        closeView()
                        if let json = json{
                            if let id = json.value(forKey: "id") as? String{
                                taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskName, id: id, duration: 600, shouldCompleteCurrentTask: false)
                            }
                        }
                    }
                })
            }else{
                closeView()
                let task = arrAllTasks[taskAddedIndex]
                if let id = task.value(forKey: "id") as? String, let taskTitle = task.value(forKey: "title") as? String{
                    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: false)
                }
            }
        }else{
            closeView()
        }
    }
    
    
    func closeView(){
        addLog(text: "popUpFocusGoalConfirmationVc:- closeView")
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.closeWindowNeedToCheckAppUrlAgain()
    }
}

extension popUpFocusGoalConfirmationVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if comboBox.stringValue.isEmpty{
            return;
        }

    }
}
