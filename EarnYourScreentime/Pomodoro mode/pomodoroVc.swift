//
//  pomodoroVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/02/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//

import Cocoa

class pomodoroVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var popUpBtnFocusType: NSPopUpButton!
    @IBOutlet weak var btnEditFocusMode: underLineButton!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet var textViewAchieve: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        isPomodoroWindowLodded = true
        lblTitle.stringValue = "It's time to focus"
        lblQuestionFirst.stringValue = "What do you want to achieve in the next 25 minutes?"
        lblQuestionSecond.stringValue = "Which focus mode do you want to use?"
        btnEditFocusMode.title = "Edit focus modes"
        btnLetsDoIt.title = "Let's do it"

        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            if let title = pomodoroInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let questionFirstText = pomodoroInfo.value(forKey: "questionFirstText") as? String{
                lblQuestionFirst.stringValue = questionFirstText
            }
            if let questionSecondText = pomodoroInfo.value(forKey: "questionSecondText") as? String{
                lblQuestionSecond.stringValue = questionSecondText
            }
            if let buttonEditFocusModeText = pomodoroInfo.value(forKey: "buttonEditFocusModeText") as? String{
                btnEditFocusMode.title = buttonEditFocusModeText
            }
            if let buttonLetsDoItText = pomodoroInfo.value(forKey: "buttonLetsDoItText") as? String{
                btnLetsDoIt.title = buttonLetsDoItText
            }
        }
        
        popUpBtnFocusType.removeAllItems()
    }
    override func viewWillAppear() {
        textViewAchieve.string = ""
        reFillFocusTypeList()
        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
            if startingFocusWindowControllerObj?.contentViewController == startingFocusModeVcObj{
                startingFocusWindowControllerObj?.close()
            }
        }
    }
    func reFillFocusTypeList(){
        popUpBtnFocusType.removeAllItems()
        for i in 0..<arrFocusType.count{
            if let name = arrFocusType[i]["name"] as? String{
                popUpBtnFocusType.addItem(withTitle: name)
            }
        }
    }
    @IBAction func popUpBtnFocusTypeClicked(_ sender: Any) {
    }
    
    @IBAction func btnEditFocusModeClicked(_ sender: Any) {
        preferencesWindowControllerObj?.showWindow(self)
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = 1
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "pomodoro mode Started")
        let calendar = Calendar.current
        endFocusModeTime = calendar.date(byAdding: .minute, value: 25, to: Date())
        startFocusModeTime = Date()
        arrFocusType[popUpBtnFocusType.indexOfSelectedItem]["isOn"] = true
        
        
        appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[popUpBtnFocusType.indexOfSelectedItem]["color"] as? String ?? "")

        for i in 0..<arrFocusType.count{
            if i != popUpBtnFocusType.indexOfSelectedItem{
                arrFocusType[i]["isOn"] = false
            }
        }
        
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        isFocusTimeType = ._HOUR_
        appdelegate?.setFocusModeTimer(hour: nil, minute: 25) 
        isFocusModeStartedFromPomodoroMode = true
        appdelegate!.focusModeStartted()
         UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
//        self.view.window?.close()
        if focusPreferencesVcObj != nil{
            if (preferencesWindowControllerObj?.window!.isVisible)!{
                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                    if tabview.selectedTabViewItemIndex == 1{
                        focusPreferencesVcObj?.reloadData()
                    }
                }
            }
        }
    }
}
