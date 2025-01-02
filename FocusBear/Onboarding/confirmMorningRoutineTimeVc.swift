//
//  confirmMorningRoutineTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 23/01/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class confirmMorningRoutineTimeVc: NSViewController {

    @IBOutlet weak var pointFirstMorningTime: NSTextField!
    @IBOutlet weak var pointSecondMorningTime: NSTextField!
    @IBOutlet weak var pointThirdMorningTime: NSTextField!
    @IBOutlet weak var pointFourthMorningTime: NSTextField!
    
    @IBOutlet weak var lblMorningRoutineTime: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnChangeThis: Button!
    
    var isConfirmTimeForMorningShown = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Confirm your morning routine"
        lblSubTitle.stringValue = "To be super clear, here's what's going to happen in the morning."
        
        btnContinue.title = "Sounds good"
        btnChangeThis.title = "Change this"
        
        pointFirstMorningTime.stringValue = "You'll do your \"Morning routine\"."
        pointSecondMorningTime.stringValue = "While you're doing your habits, your computer will be locked."
        pointThirdMorningTime.stringValue = "(You can unlock it if you have an emergency)."
        pointFourthMorningTime.stringValue = "After you finish your habits, your computer will be unlocked and Focus Bear will help you avoid distractions during your workday."
        if let confirmMorningRoutineTimeVcInfo = configjson.value(forKey: "confirmMorningRoutineTimeVcInfo") as? NSDictionary{
            lblTitle.stringValue = confirmMorningRoutineTimeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = confirmMorningRoutineTimeVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnContinue.title = confirmMorningRoutineTimeVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            btnChangeThis.title = confirmMorningRoutineTimeVcInfo.value(forKey: "buttonReviewText") as? String ?? btnChangeThis.title
            pointFirstMorningTime.stringValue = confirmMorningRoutineTimeVcInfo.value(forKey: "pointFirstMorningTimeText") as? String ?? pointFirstMorningTime.stringValue
            pointSecondMorningTime.stringValue = confirmMorningRoutineTimeVcInfo.value(forKey: "pointSecondMorningTimeText") as? String ?? pointSecondMorningTime.stringValue
            pointThirdMorningTime.stringValue = confirmMorningRoutineTimeVcInfo.value(forKey: "pointThirdMorningTimeText") as? String ?? pointThirdMorningTime.stringValue
            pointFourthMorningTime.stringValue = confirmMorningRoutineTimeVcInfo.value(forKey: "pointFourthMorningTimeText") as? String ?? pointFourthMorningTime.stringValue
        }
    }
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 8)
        showOnboardingBellIcon(view: self.view, screen: "confirm-morning-routine-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    override func viewWillAppear() {
        var timeText = "From <TIME>:"
        if let confirmMorningRoutineTimeVcInfo = configjson.value(forKey: "confirmMorningRoutineTimeVcInfo") as? NSDictionary{
            timeText = confirmMorningRoutineTimeVcInfo.value(forKey: "timeText") as? String ?? timeText
        }
        timeText = timeText.replacingOccurrences(of: "<TIME>", with: askWorkTimeVcObj!.morningRoutineTime)
        lblMorningRoutineTime.stringValue = timeText
        btnChangeThis.buttonColor = NSColor.white.cgColor
    }
    @IBAction func btnChangeThisClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "go-back-confirm-morning-routine", metadata: [:])
        mainViewControllerObj!.showAskWorkTimeVc()
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "continue-confirm-morning-routine", metadata: [:])
        isConfirmTimeForMorningShown = true
        mainViewControllerObj!.showConfirmEveningRoutineTimeVc()
    }
}

