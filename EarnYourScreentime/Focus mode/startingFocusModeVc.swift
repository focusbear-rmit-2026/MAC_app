//
//  startingFocusModeVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/02/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//

import Cocoa

class startingFocusModeVc: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var lblMinute: NSTextField!
    @IBOutlet weak var lblHour: NSTextField!
    @IBOutlet weak var textFieldMinutesValue: NSTextField!
    @IBOutlet weak var textFieldHourValue: NSTextField!
    @IBOutlet weak var lblHowMuchTime: NSTextField!
    @IBOutlet weak var btnStartFocus: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet var textViewQuestion: NSTextView!
    
    var focusIndex = 0
    var focusType = ""
    var titleText = "Starting Focus type - <FOCUSTYPE>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        focusModeStartWindowLodded = true
        btnStartFocus.title = "Start Focus"
        lblHowMuchTime.stringValue = "How much time to focus for:"
        lblHour.stringValue = "hours"
        lblMinute.stringValue = "minutes"
        textFieldMinutesValue.delegate = self
        textFieldHourValue.delegate = self
        lblQuestion.stringValue = "What do you plan to achieve during this focus block?"
        
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                if let title = startingFocusModeInfo.value(forKey: "title") as? String{
                    titleText = title
                }
                if let questionText = startingFocusModeInfo.value(forKey: "questionText") as? String{
                    lblQuestion.stringValue = questionText
                }
                if let buttonStartFocusText = startingFocusModeInfo.value(forKey: "buttonStartFocusText") as? String{
                    btnStartFocus.title = buttonStartFocusText
                }
                if let howMuchTimeText = startingFocusModeInfo.value(forKey: "howMuchTimeText") as? String{
                    lblHowMuchTime.stringValue = howMuchTimeText
                }
                if let hoursText = startingFocusModeInfo.value(forKey: "hoursText") as? String{
                    lblHour.stringValue = hoursText
                }
                if let minutesText = startingFocusModeInfo.value(forKey: "minutesText") as? String{
                    lblMinute.stringValue = minutesText
                }
            }
        }
        
    }

    override func viewWillAppear() {
        textViewQuestion.string = ""
    }
    
    @IBAction func btnStartFocusClicked(_ sender: Any) {
        let calendar = Calendar.current
        let totoalMinutes = (textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
        endFocusModeTime = calendar.date(byAdding: .minute, value: totoalMinutes, to: Date())
        startFocusModeTime = Date()
        arrFocusType[focusIndex]["isOn"] = true
        if focusPreferencesVcObj != nil{
            if (preferencesWindowControllerObj?.window!.isVisible)!{
                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                    if tabview.selectedTabViewItemIndex == 1{
                        focusPreferencesVcObj?.reloadData()
                    }
                }
            }
        }
        appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[focusIndex]["color"] as? String ?? "")
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        isFocusTimeType = ._HOUR_
        appdelegate?.setFocusModeTimer(hour: nil, minute: totoalMinutes)
        isFocusModeStartedFromPomodoroMode = false
        appdelegate!.focusModeStartted()
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        self.view.window?.close()
    }
    
    
    func ResetData(focusModeIndex:Int, focusType:String){
        if isPomodoroWindowLodded{
            if pomodoroWindowControllerObj?.window?.isVisible ?? false{
                pomodoroWindowControllerObj?.window?.close()
            }
        }
        self.focusType = focusType
        self.focusIndex = focusModeIndex
        textFieldHourValue.stringValue = "00"
        textFieldMinutesValue.stringValue = "20"
        btnStartFocus.isEnabled = true
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusType)//"Starting Focus type - \(focusType)"
    }
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldHourValue{
                var count = textfield.integerValue
                if count > 12{
                    count = 12
                }
                if count < 10{
                    textfield.stringValue = "0\(count)"
                }else{
                    textfield.stringValue = "\(count)"
                }
                
                if textfield.stringValue.count > 2{
                    textfield.stringValue = "12"
                }
                
                if textFieldMinutesValue.stringValue == "00" && textFieldHourValue.stringValue == "00"{
                    btnStartFocus.isEnabled = false
                }else{
                    btnStartFocus.isEnabled = true
                }
            }else if textfield == textFieldMinutesValue{
                var count = textfield.integerValue
                if count > 59{
                    count = 59
                }
                if count < 10{
                    textfield.stringValue = "0\(count)"
                }else{
                    textfield.stringValue = "\(count)"
                }
                if textfield.stringValue.count > 2{
                    textfield.stringValue = "59"
                }
                if textFieldMinutesValue.stringValue == "00" && textFieldHourValue.stringValue == "00"{
                    btnStartFocus.isEnabled = false
                }else{
                    btnStartFocus.isEnabled = true
                }
            }
        }
    }
}
