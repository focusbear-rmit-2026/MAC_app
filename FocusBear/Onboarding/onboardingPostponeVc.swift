//
//  onboardingPostponeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingPostponeVc: NSViewController {
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnCancelPostpone: cursorButton!
    @IBOutlet weak var popUpButtonSelectMinutes: NSPopUpButton!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var lblSelectMinutes: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        lblTitle.stringValue = "If you have something urgent, you can postpone the Onboarding process for few Minutes."
        lblSelectMinutes.stringValue = "Select minutes to postpone:"
        btnPostpone.title = "Postpone Onboarding"
        popUpButtonSelectMinutes.removeAllItems()
        popUpButtonSelectMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "60", "90"])
        
        if let onboardingPostponeVcInfo = configjson.value(forKey: "onboardingPostponeVcInfo") as? NSDictionary{
            lblTitle.stringValue = onboardingPostponeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSelectMinutes.stringValue = onboardingPostponeVcInfo.value(forKey: "selectMinutesText") as? String ?? lblSelectMinutes.stringValue
            btnPostpone.title = onboardingPostponeVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
        }
        
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "btnPostponeClicked.")
        self.dismiss(self)
        getWelcomeOnboardingWindowObject().close()
        appdelegate!.postponeOnboardingHabitFor(minutes: Int(popUpButtonSelectMinutes.title) ?? 15)
        allApiObject.capturePosthog(event: "postpone-initial-onboarding", metadata: [:])
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        addLog(text: "btnCloseClicked.")
        self.dismiss(self)
    }
}
///dock icon k click per ye view vapas lao
