//
//  confirmRoutineDurationVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/08/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class confirmRoutineDurationVc: NSViewController {

    @IBOutlet weak var btnClose: NSButton!
    @IBOutlet weak var boxExtra: NSBox!
    @IBOutlet weak var stackViewButtons: NSStackView!
    @IBOutlet weak var btnNo: Button!
    @IBOutlet weak var btnYes: Button!
    @IBOutlet weak var lblTitleConfirm: NSTextField!
    @IBOutlet weak var lblMinimumDuration: NSTextField!
    @IBOutlet weak var lblMaximumDuration: NSTextField!
    
    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var totalSeconds = 0
    var btnTitleLetsDoIt = "Let's do it"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "How much time do you have for your habits today?"
        if let confirmRoutineDurationVcInfo = configjson.value(forKey: "confirmRoutineDurationVcInfo") as? NSDictionary{
            lblTitle.stringValue = confirmRoutineDurationVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnTitleLetsDoIt = confirmRoutineDurationVcInfo.value(forKey: "buttonLetsDoItText") as? String ?? btnTitleLetsDoIt
        }
        
        lblMinimumDuration.stringValue = "0\(minutesMText)"
        btnYes.buttonColor = NSColor.white.cgColor
        stackViewButtons.isHidden = false
        lblTitleConfirm.isHidden = true
        btnYes.isHidden = true
    }
    func resetData(totalSeconds:Int){
        lblMaximumDuration.stringValue = getStringTimeFromSeconds(seconds: totalSeconds)
        slider.maxValue = Double(totalSeconds)
        slider.integerValue = totalSeconds
        self.totalSeconds = totalSeconds
        stackViewButtons.isHidden = false
        btnYes.isHidden = true
        btnNo.title = btnTitleLetsDoIt
        lblTitleConfirm.isHidden = true
        sliderClicked(self)
    }

    @IBAction func btnYesClicked(_ sender: Any) {
        if slider.integerValue == 0{
            stackViewButtons.isHidden = true
            lblTitleConfirm.isHidden = true
            slider.doubleValue = ( slider.maxValue * 25 ) / 100
            sliderClicked(self)
        }
    }
    @IBAction func btnNoClicked(_ sender: Any) {
        if slider.integerValue == 0{
            allApiObject.capturePosthog(event: "routine-duration-selected", metadata: ["duration":self.slider.integerValue])
            let sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
            allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
                print("forceCompleteCurrentSequence success")
            })
            
            self.dismiss(self)
            
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
            isHabitAlreadyShowed = true
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            currentState = ._NOTHING_
            mainViewControllerObj?.setActivityTimer()
            addLog(text: "morning habit skipped by user")
        }else if slider.integerValue == totalSeconds{// button ok
            allApiObject.capturePosthog(event: "routine-duration-selected", metadata: ["duration":slider.integerValue])
            self.dismiss(self)
        }else{
            allApiObject.capturePosthog(event: "routine-duration-selected", metadata: ["duration":slider.integerValue])
            self.dismiss(self)
            firstViewControllerObj?.showChooseHabitsView()
        }
    }
    @IBAction func sliderClicked(_ sender: Any) {
        addLog(text: "sliderClicked")
        addLog(text: "selected duration:- \(self.slider.integerValue)")
        if currentState == ._MORNING_HABIT_{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsBeginMorningHabitClickedDate)
        }else if currentState == ._EVENING_HABIT_{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsBeginEveningHabitClickedDate)
        }
        if slider.integerValue == 0{
            stackViewButtons.isHidden = false
            btnYes.isHidden = false
            btnNo.isHidden = false
            boxExtra.isHidden = false
            lblTitleConfirm.isHidden = false
            
            lblTitleConfirm.stringValue = "Are you sure? Can you make time for just one habit so you keep the routine going?"
            if let confirmRoutineDurationVcInfo = configjson.value(forKey: "confirmRoutineDurationVcInfo") as? NSDictionary{
                lblTitleConfirm.stringValue = confirmRoutineDurationVcInfo.value(forKey: "alertDoOneHabitText") as? String ?? lblTitleConfirm.stringValue
            }
            
            btnYes.title = buttonYesText
            btnNo.title = buttonNoText
            
        }else if slider.integerValue == totalSeconds{
            stackViewButtons.isHidden = false
            btnYes.isHidden = true
            btnNo.isHidden = false
            boxExtra.isHidden = true
            lblTitleConfirm.isHidden = false
            
            lblTitleConfirm.stringValue = "Awesome - you'll get through all your habits!"
            if let confirmRoutineDurationVcInfo = configjson.value(forKey: "confirmRoutineDurationVcInfo") as? NSDictionary{
                lblTitleConfirm.stringValue = confirmRoutineDurationVcInfo.value(forKey: "alertDoAllHabitsText") as? String ?? lblTitleConfirm.stringValue
            }
            btnNo.title = btnTitleLetsDoIt
        }else{
            stackViewButtons.isHidden = false
            btnYes.isHidden = true
            btnNo.isHidden = false
            boxExtra.isHidden = true
            lblTitleConfirm.isHidden = false
            
            lblTitleConfirm.stringValue = "Nice - even though you won't get through all your habits, you're still going to make progress."
            if let confirmRoutineDurationVcInfo = configjson.value(forKey: "confirmRoutineDurationVcInfo") as? NSDictionary{
                lblTitleConfirm.stringValue = confirmRoutineDurationVcInfo.value(forKey: "alertDoSomeHabitsText") as? String ?? lblTitleConfirm.stringValue
            }
            btnNo.title = buttonOkText
        }
    }

    
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            
            completionHandler(true)
            return
        })
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        btnNoClicked(self)
    }
}
