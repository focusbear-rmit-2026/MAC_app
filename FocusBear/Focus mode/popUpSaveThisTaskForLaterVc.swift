//
//  popUpSaveThisTaskForLaterVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 24/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class popUpSaveThisTaskForLaterVc: NSViewController {

    @IBOutlet weak var lblTitleTaskTitle: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var btnBlock: Button!
    @IBOutlet weak var btnYesSave: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Do you want to save this as a task for later?"
        btnYesSave.title = "Yes please"
        btnBlock.title = "No - Just block it"
        lblTitleTaskTitle.stringValue = "Task title:"
        btnBlock.isSecondaryButton = true
        
        if let popUpSaveThisTaskForLaterVcInfo = configjson.value(forKey: "popUpSaveThisTaskForLaterVcInfo") as? NSDictionary{
            lblTitle.stringValue = popUpSaveThisTaskForLaterVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnYesSave.title = popUpSaveThisTaskForLaterVcInfo.value(forKey: "buttonYesText") as? String ?? btnYesSave.title
            btnBlock.title = popUpSaveThisTaskForLaterVcInfo.value(forKey: "buttonJustBlockItText") as? String ?? btnBlock.title
            lblTitleTaskTitle.stringValue = popUpSaveThisTaskForLaterVcInfo.value(forKey: "titleTask") as? String ?? lblTitleTaskTitle.stringValue
        }
    }
    
    func resetData(url:String){
        var taskNameString = "To work on: <URL>"
        if let popUpSaveThisTaskForLaterVcInfo = configjson.value(forKey: "popUpSaveThisTaskForLaterVcInfo") as? NSDictionary{
            taskNameString = popUpSaveThisTaskForLaterVcInfo.value(forKey: "taskNameString") as? String ?? taskNameString
        }
        taskNameString = taskNameString.replacingOccurrences(of: "<URL>", with: url)
        textView.string = taskNameString
        textView.window?.makeFirstResponder(textView)
    }// Task title
    
    @IBAction func btnYesSaveClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpSaveThisTaskForLaterVc:- btnYesSaveClicked")
        let taskName = textView.string

        // Fetch existing tasks first to avoid creating a duplicate (#1679).
        // If a task with the same name (case-insensitive) already exists,
        // reuse it instead of creating a new one.
        // getAllTasks fires its completion on a background (URLSession) thread,
        // so hop to the main thread before doing any UI/addTask work.
        allApiObject.getAllTasks { [weak self] existingTasks in
            DispatchQueue.main.async {
                guard self != nil else { return }
                let tasks = existingTasks ?? []

                if let match = TaskDeduplicationHelper.existingTask(named: taskName, in: tasks) {
                    addLog(text: "popUpSaveThisTaskForLaterVc: task '\(taskName)' already exists (id: \(match.task.value(forKey: "id") as? String ?? "?")) – reusing, skipping creation.")
                    if let id = match.task.value(forKey: "id") as? String {
                        taskPlayerVcObj?.addTaskInCurrentList(taskName: taskName, id: id, duration: 600)
                    }
                } else {
                    let today = Date()
                    let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
                    let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                    allApiObject.addTask(title: taskName, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result, json in
                        if result {
                            addLog(text: "\(taskName) task created successfully.")
                            DispatchQueue.main.async { [weak self] in
                                guard self != nil else { return }
                                if let json = json {
                                    if let id = json.value(forKey: "id") as? String {
                                        taskPlayerVcObj?.addTaskInCurrentList(taskName: taskName, id: id, duration: 600)
                                    }
                                }
                            }
                        }
                    })
                }
            }
        }
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.blockClicked()
    }
    
    @IBAction func btnBlockClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpSaveThisTaskForLaterVc:- btnBlockClicked")
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.blockClicked()
    }
}
