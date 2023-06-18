//
//  popupAppointmentTime.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class popupAppointmentTimeVc: NSViewController {

    @IBOutlet weak var btnBackToHabits: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var duration = 300
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        btnOk.title = "Thanks!"
        btnBackToHabits.title = "Back to habits - I don't need to attend"
        
        if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
            lblTitle.stringValue = popupAppointmentTimeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            btnBackToHabits.title = popupAppointmentTimeVcInfo.value(forKey: "buttonBackToHabitsText") as? String ?? btnBackToHabits.title
        }
        btnBackToHabits.buttonColor = NSColor.white.cgColor
    }
    func resetView(title:String, duration:Int){
        var message = "It looks like you have an appointment that is about to start: <EVENT_TITLE>. Pausing your habits so you can attend the appointment."
        if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
            message = popupAppointmentTimeVcInfo.value(forKey: "title") as? String ?? message
            btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            btnBackToHabits.title = popupAppointmentTimeVcInfo.value(forKey: "buttonBackToHabitsText") as? String ?? btnBackToHabits.title
        }
        
        message = message.replacingOccurrences(of: "<EVENT_TITLE>", with: title)
        lblTitle.stringValue = message
        if currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
            btnBackToHabits.isHidden = true
        }else{
            btnBackToHabits.isHidden = false
        }
        self.duration = duration
        
        
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.window?.close()

        
        if lastCurrentState == ._MORNING_HABIT_{
            mainViewControllerObj?.postponeMorningHabitFor(minutes: 0, secondsToPostpone: duration)
        }else if lastCurrentState == ._EVENING_HABIT_{
            mainViewControllerObj?.postponeEveningHabitFor(minutes: 0, secondsToPostpone: duration)
        }else if lastCurrentState == ._ACTIVITY_{
            mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 0, secondsToPostpone: duration)
        }
        
    }
    
    @IBAction func btnBackToHabitsClicked(_ sender: Any) {
        self.view.window?.close()
        if currentHabitPlaying == nil && currentActivityPlaying == nil{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
        }else{
            getSmallCountDownWindowObject().showWindow(self)
        }
        mainViewControllerObj?.abortCancel()
    }
    
}
