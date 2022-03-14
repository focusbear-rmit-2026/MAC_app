//
//  focusCompletedVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/02/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//

import Cocoa

class focusCompletedVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet var textViewAchieve: NSTextView!
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet var textViewDistractions: NSTextView!
    @IBOutlet weak var btnTakeBreak: Button!
    
    var currentFocusModeName = ""
    var fromShutOff = false
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonFinishDayText = "Finish up for the day"
    var buttonTakeBreakText = "Take a 5 minute break"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "You did it!"
        lblQuestionFirst.stringValue = "What did you achieve during this time?"
        lblQuestionSecond.stringValue = "Any distractions?"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                if let title = focusCompletedInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = focusCompletedInfo.value(forKey: "subTitle") as? String{
                    subTitleText = subTitle
                }
                if let questionFirstText = focusCompletedInfo.value(forKey: "questionFirstText") as? String{
                    lblQuestionFirst.stringValue = questionFirstText
                }
                if let questionSecondText = focusCompletedInfo.value(forKey: "questionSecondText") as? String{
                    lblQuestionSecond.stringValue = questionSecondText
                }
                if let buttonFinishDayText = focusCompletedInfo.value(forKey: "buttonFinishDayText") as? String{
                    self.buttonFinishDayText = buttonFinishDayText
                }
                if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonTakeBreakText") as? String{
                    self.buttonTakeBreakText = buttonTakeBreakText
                }
            }
        }
        
    }
    
    override func viewWillAppear() {
        
    }
    
    func resetData(focusModeName:String, fromShutOff:Bool){
        self.currentFocusModeName = focusModeName
        self.fromShutOff = fromShutOff
        print("fromShutOff")
        print(fromShutOff)
        textViewAchieve.string = ""
        textViewDistractions.string = ""
        if fromShutOff{
            btnTakeBreak.title = buttonFinishDayText
        }else{
            btnTakeBreak.title = buttonTakeBreakText
        }
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)//"You have successfully completed the focus block - \(currentFocusModeName)"
    }
    @IBAction func btnTakeBreakClicked(_ sender: Any) {
        
        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        addEntryInCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: textViewAchieve.string, distractionsEncountered: textViewDistractions.string, abortReason: "", feedback: "")
        currentState = ._NOTHING_
        if fromShutOff{
            appdelegate?.shutOffMac()
        }else{
            if isFocusModeStartedFromPomodoroMode{
                addLog(text: "pomodoro mode Finished")
                appdelegate?.setTimerForPomodoroMode()
            }
            self.view.window?.close()
        }
    }
    
}
