//
//  lateMorningHabitPopupVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/01/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class lateMorningHabitPopupVc: NSViewController {

    @IBOutlet weak var btnSkip: Button!
    @IBOutlet weak var btnDoHabits: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Hiya, do you still want to do your morning routine today or skip it?"
        
        btnDoHabits.title = "Do my habits"
        btnSkip.title = "Skip it"
        if let lateMorningHabitPopupVcInfo = configjson.value(forKey: "lateMorningHabitPopupVcInfo") as? NSDictionary{
            lblTitle.stringValue = lateMorningHabitPopupVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnDoHabits.title = lateMorningHabitPopupVcInfo.value(forKey: "buttonDoHabitsText") as? String ?? btnDoHabits.title
            btnSkip.title = lateMorningHabitPopupVcInfo.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
        }
        
        btnSkip.buttonColor = NSColor.white.cgColor
    }
    override func viewWillAppear() {
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let currentDate = Date()
        let diffHours = Calendar.current.dateComponents([.hour], from: startDate, to: currentDate).hour ?? 0
        
        var subTitle = "(Asking because it's <HOUR> hours since your routine start time and it might not make sense to do it today)"
        if let lateMorningHabitPopupVcInfo = configjson.value(forKey: "lateMorningHabitPopupVcInfo") as? NSDictionary{
            subTitle = lateMorningHabitPopupVcInfo.value(forKey: "subTitle") as? String ?? subTitle
        }
        lblSubTitle.stringValue = subTitle.replacingOccurrences(of: "<HOUR>", with: "\(diffHours)")
    }
    @IBAction func btnSkipClicked(_ sender: Any) {
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
    }
    
    @IBAction func btnDoHabitsClicked(_ sender: Any) {
        self.dismiss(self)
        firstViewControllerObj?.showLimitedUsgaeViewIfNeeded()
        var isAnyNagVisible = false
        if alertLimitedUsageVcObj != nil{
            if alertLimitedUsageVcObj?.presentingViewController == self{
                isAnyNagVisible = true
            }
        }
        if !isAnyNagVisible{
            firstViewControllerObj?.showConfirmRoutineDurationViewIfNeeded()
        }
    }
}
