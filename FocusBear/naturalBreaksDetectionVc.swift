//
//  customAlertVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class naturalBreaksDetectionVc: NSViewController {

    @IBOutlet weak var btnSecond: Button!
    @IBOutlet weak var btnFirst: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var isNormalState = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    func resetView(){
        lblTitle.stringValue = "It looks like you're on a break. Well done on taking care of yourself."
        lblSubTitle.isHidden = true
        btnFirst.title = "Thanks - I feel great"
        btnSecond.title = "You're wrong! I wasn't on a break"
        btnSecond.buttonColor = NSColor.white.cgColor
        isNormalState = true
        
        if let naturalBreaksDetectionVcInfo = configjson.value(forKey: "naturalBreaksDetectionVcInfo") as? NSDictionary{
            lblTitle.stringValue = naturalBreaksDetectionVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnFirst.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonThanksText") as? String ?? btnFirst.title
            btnSecond.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonWrongDetectionText") as? String ?? btnSecond.title
        }
    }
    @IBAction func btnFirstClicked(_ sender: Any) {
        if isNormalState{
            self.view.window?.close()
        }else{
            self.view.window?.close()
//            if currentState
            if currentState == ._POSTPON_MORNING_HABIT_{
                isBreakActivityExecuteFromPostponeMorningHabit = true
            }else if currentState == ._POSTPON_EVENING_HABIT_{
                isBreakActivityExecuteFromPostponeEveningHabit = true
            }
            if !isMainWindowLodded{
                mainWindowControllerObj?.loadWindow()
            }
            mainViewControllerObj?.executeBreakActivities()
        }
    }
    
    @IBAction func btnSecondClicked(_ sender: Any) {
        if isNormalState{
            allApiObject.capturePosthog(event: "wrong-decision-i-wasnt-on-break", metadata: [:])
            lblTitle.stringValue = "Ok do you want to take a break now 😅?"
            btnFirst.title = "Yup I need a break now"
            btnSecond.title = "No - I'll take later"
            isNormalState = false
            
            if let naturalBreaksDetectionVcInfo = configjson.value(forKey: "naturalBreaksDetectionVcInfo") as? NSDictionary{
                lblTitle.stringValue = naturalBreaksDetectionVcInfo.value(forKey: "titleTakeBreak") as? String ?? lblTitle.stringValue
                btnFirst.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonStartBreakText") as? String ?? btnFirst.title
                btnSecond.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonTakeBreakLaterText") as? String ?? btnSecond.title
            }
        }else{
            self.view.window?.close()
        }
    }
    
}
