//
//  askIntentionAllowedFocusModeActivity.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/08/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class askIntentionAllowedFocusModeActivity: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet weak var lblAskIntention: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    var titleText = "Starting Focus type - <FOCUSTYPE>"
    var durationSeconds:Int = 0
    var name:String = ""
    var currentHabit: habit!
    var currentTimerValue:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                if let title = startingFocusModeInfo.value(forKey: "title") as? String{
                    titleText = title
                }
                if let questionText = startingFocusModeInfo.value(forKey: "questionText") as? String{
                    lblAskIntention.stringValue = questionText
                }
            }
        }
        if let selectHabitsLaterInfo = configjson.value(forKey: "selectHabitsLaterInfo") as? NSDictionary{
            btnContinue.title = selectHabitsLaterInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
    }
    
    func resetData(focusMode:String, intention:String, durationSeconds:Int, name:String,currentHabit: habit, currentTimerValue:Int){
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusMode)
        textViewIntention.string = intention
        self.durationSeconds = durationSeconds
        self.name = name
        self.currentHabit = currentHabit
        self.currentTimerValue = currentTimerValue
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        if let focusModeId = currentHabit.allowedFocusMode{
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["id"] as? String == focusModeId{
                    arrFocusType[i]["lastIntentionUsed"] = textViewIntention.string
                    break;
                }
            }
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        updateAllFocusModes()
        self.dismiss(self)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: durationSeconds, name: name, currentHabit: currentHabit, currentTimerValue: currentTimerValue)
    }
    
}
