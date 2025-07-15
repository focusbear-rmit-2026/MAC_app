//
//  onboardingBlockingScheduleVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/11/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingBlockingScheduleVc: NSViewController { // not in use 

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var radioBtnFirst: NSButton!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var radioBtnSecond: NSButton!
    @IBOutlet weak var lblDescriptionThird: NSTextField!
    @IBOutlet weak var radioBtnThird: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblDescriptionThird.isHidden = true 
        
        lblTitle.stringValue = "Blocking Schedule"
        lblSubTitle.stringValue = "When do you want to block distracting sites?"
        radioBtnFirst.title = "Automatically (until the end of the workday)"
        lblDescriptionFirst.stringValue = "Block distracting sites until you finish your work/study. You'll get some free time before bed (check your socials guilt free!). When it's time to sleep, sites are blocked again."
        radioBtnSecond.title = "Manually (when I switch it on)"
        lblDescriptionSecond.stringValue = "Block distracting sites when you click the Start Focus Session button"
        radioBtnThird.title = "Advanced (customised blocking schedule)"
        lblDescriptionThird.stringValue = "Coming soon"
        btnContinue.title = buttonContinueText
        
        
        if let onboardingBlockingScheduleVcInfo = configjson.value(forKey: "onboardingBlockingScheduleVcInfo") as? NSDictionary{
            lblTitle.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            radioBtnFirst.title = onboardingBlockingScheduleVcInfo.value(forKey: "radioBtnFirstText") as? String ?? radioBtnFirst.title
            lblDescriptionFirst.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            radioBtnSecond.title = onboardingBlockingScheduleVcInfo.value(forKey: "radioBtnSecondText") as? String ?? radioBtnSecond.title
            lblDescriptionSecond.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            radioBtnThird.title = onboardingBlockingScheduleVcInfo.value(forKey: "radioBtnThirdText") as? String ?? radioBtnThird.title
            lblDescriptionThird.stringValue = onboardingBlockingScheduleVcInfo.value(forKey: "descriptionThirdText") as? String ?? lblDescriptionThird.stringValue
        }
        
        addLog(text: "onboardingBlockingScheduleVc shown")
        allApiObject.capturePosthog(event: "onboarding-blocking-schedule-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 4)
        showOnboardingBellIcon(view: self.view, screen: "onboarding-blocking-schedule-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    
    override func viewWillAppear() {
        radioBtnFirst.state = .off
        radioBtnSecond.state = .off
        radioBtnThird.state = .off
        btnContinue.isEnabled = false
    }
    
    @IBAction func radioBtnFirstClicked(_ sender: Any) {
        radioBtnSecond.state = .off
        radioBtnThird.state = .off
        btnContinue.isEnabled = true
    }
    
    @IBAction func radioBtnSecondClicked(_ sender: Any) {
        radioBtnFirst.state = .off
        radioBtnThird.state = .off
        btnContinue.isEnabled = true
    }
    
    @IBAction func radioBtnThirdClicked(_ sender: Any) {
        radioBtnFirst.state = .off
        radioBtnSecond.state = .off
        btnContinue.isEnabled = false
        lblDescriptionThird.isHidden = false
        allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"on_a_custom_schedule"])
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingBlockingScheduleVc:- Button Continue clicked")
        if radioBtnFirst.state == .on{
            allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"until_i_finish_work"])
            UserDefaults.standard.set(BLOCKINGSCHEDULE._UNTIL_I_FINISH_WORK_.rawValue, forKey: kUserdefaultsBlockingScheduleFromOnboarding)
        }else if radioBtnSecond.state == .on{
            allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"when_i_tell_you_to"])
            UserDefaults.standard.set(BLOCKINGSCHEDULE._WHEN_START_FOCUS_SESSION_.rawValue, forKey: kUserdefaultsBlockingScheduleFromOnboarding)
        }else if radioBtnThird.state == .on{
            allApiObject.capturePosthog(event: "choose-focus-schedule", metadata: ["schedule-type":"on_a_custom_schedule"])
            UserDefaults.standard.set(BLOCKINGSCHEDULE._CUSTOM_SCHEDULE_.rawValue, forKey: kUserdefaultsBlockingScheduleFromOnboarding)
        }
        
        
    }
}
