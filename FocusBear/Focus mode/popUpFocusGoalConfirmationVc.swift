//
//  popUpFocusGoalConfirmationVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 24/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class popUpFocusGoalConfirmationVc: NSViewController {

    @IBOutlet weak var btnNoCurrentTaskAdded: Button!
    @IBOutlet weak var btnYesRelevant: Button!
    @IBOutlet weak var btnWorkingOnAnotherGoal: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnNoCurrentTaskAdded.buttonColor = NSColor.white.cgColor
        btnNoCurrentTaskAdded.title = "No current task - let me quickly enter one"
        lblTitle.stringValue = "Are you still working on \"<TASK>\" as part of your focus goal: \"<GOAL>\"?"
        btnWorkingOnAnotherGoal.title = "No I'm working on something else now"
        btnYesRelevant.title = "Yes and this site is relevant"
        
        if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
            lblTitle.stringValue = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoalAndTask") as? String ?? lblTitle.stringValue
            btnWorkingOnAnotherGoal.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonWorkingSomethingElseText") as? String ?? btnWorkingOnAnotherGoal.title
            btnYesRelevant.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonAppRelevantText") as? String ?? btnYesRelevant.title
            btnNoCurrentTaskAdded.title = popUpFocusGoalConfirmationVcInfo.value(forKey: "buttonNoCurrentTaskAdded") as? String ?? btnNoCurrentTaskAdded.title
        }
        btnWorkingOnAnotherGoal.buttonColor = NSColor.white.cgColor
    }
    
    func resetData(goal:String, task:String?, isApp:Bool){
        if let task = task{
            var title = "Are you still working on \"<TASK>\" as part of your focus goal: \"<GOAL>\"?"
            if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                title = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoalAndTask") as? String ?? title
            }
            title = title.replacingOccurrences(of: "<TASK>", with: task)
            title = title.replacingOccurrences(of: "<GOAL>", with: goal)
            lblTitle.stringValue = title
            btnNoCurrentTaskAdded.isHidden = true
        }else{
            var title = "Is your focus goal still: \"<GOAL>\"?"
            if let popUpFocusGoalConfirmationVcInfo = configjson.value(forKey: "popUpFocusGoalConfirmationVcInfo") as? NSDictionary{
                title = popUpFocusGoalConfirmationVcInfo.value(forKey: "titleGoal") as? String ?? title
            }
            title = title.replacingOccurrences(of: "<GOAL>", with: goal)
            lblTitle.stringValue = title
            btnNoCurrentTaskAdded.isHidden = false
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
        popUpBlockConfirmVcObj?.showoPopUpAddNewFocusGoalView()
    }
    
    @IBAction func btnYesRelevantClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpFocusGoalConfirmationVc:- YesRelevantClicked")
        self.view.removeFromSuperview()
        popUpBlockConfirmVcObj?.showConvincedAiPopUpBox(allowedByConvinceAiAlready:false, reason: "")
    }
}
