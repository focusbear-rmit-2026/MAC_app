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
        btnBlock.buttonColor = NSColor.white.cgColor
        
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
    }// Task title
    
    @IBAction func btnYesSaveClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpSaveThisTaskForLaterVc:- btnYesSaveClicked")
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
        let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        allApiObject.addTask(title: textView.string, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result,json in
            if result{
                DispatchQueue.main.async { [self] in
                    if taskPlayerWcObj != nil{
                        if taskPlayerWcObj?.window?.isVisible ?? false{
                            if let json = json{
                                if let id = json.value(forKey: "id") as? String{
                                    taskPlayerVcObj?.addTaskInCurrentList(taskName: textView.string, id: id, duration: 600)
                                }
                            }
                            
                        }
                    }
                }
            }
        })
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.blockClicked()
    }
    
    @IBAction func btnBlockClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpSaveThisTaskForLaterVc:- btnBlockClicked")
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.blockClicked()
    }
}
