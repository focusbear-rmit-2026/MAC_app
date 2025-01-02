//
//  confirmEveningRoutineVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 22/01/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class confirmEveningRoutineTimeVc: NSViewController {

    @IBOutlet weak var pointFirstRelaxTime: NSTextField!
    @IBOutlet weak var pointSecondRelaxTime: NSTextField!
    @IBOutlet weak var pointThirdRelaxTime: NSTextField!
    
    @IBOutlet weak var pointFirstEveningRoutineTime: NSTextField!
    @IBOutlet weak var pointSecondEveningRoutineTime: NSTextField!
    @IBOutlet weak var pointThirdEveningRoutineTime: NSTextField!
    @IBOutlet weak var pointFourthEveningRoutineTime: NSTextField!
    
    @IBOutlet weak var lblEveningRoutineTime: NSTextField!
    @IBOutlet weak var lblRelaxModeTime: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnChangeThis: Button!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        btnContinue.title = "Sounds good"
        btnChangeThis.title = "Change this"
        if let confirmMorningRoutineTimeVcInfo = configjson.value(forKey: "confirmMorningRoutineTimeVcInfo") as? NSDictionary{
            btnContinue.title = confirmMorningRoutineTimeVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            btnChangeThis.title = confirmMorningRoutineTimeVcInfo.value(forKey: "buttonReviewText") as? String ?? btnChangeThis.title
        }
        
        lblTitle.stringValue = "Confirm your evening routine"
        lblSubTitle.stringValue = "To be super clear, here's what's going to happen in the evening."
        
        
        pointFirstRelaxTime.stringValue = "You'll enter \"Relax mode\"."
        pointSecondRelaxTime.stringValue = "You can use any app (including websites that are normally blocked)."
        pointThirdRelaxTime.stringValue = "Good for playing games or unrestricted browsing. You've earned it after a hard day of focusing."
        
        pointFirstEveningRoutineTime.stringValue = "You'll enter \"Wind Down mode\"."
        pointSecondEveningRoutineTime.stringValue = "It's time to do your evening habits and get ready to sleep."
        pointThirdEveningRoutineTime.stringValue = "Games and other websites are blocked."
        pointFourthEveningRoutineTime.stringValue = "If you really need to keep using your computer, you can unlock it but we recommend sticking to your routine."
        
        if let confirmEveningRoutineTimeVcInfo = configjson.value(forKey: "confirmEveningRoutineTimeVcInfo") as? NSDictionary{
            lblTitle.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            pointFirstEveningRoutineTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointFirstEveningTimeText") as? String ?? pointFirstEveningRoutineTime.stringValue
            pointSecondEveningRoutineTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointSecondEveningTimeText") as? String ?? pointSecondEveningRoutineTime.stringValue
            pointThirdEveningRoutineTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointThirdEveningTimeText") as? String ?? pointThirdEveningRoutineTime.stringValue
            pointFourthEveningRoutineTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointFourthEveningTimeText") as? String ?? pointFourthEveningRoutineTime.stringValue
            
            pointFirstRelaxTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointFirstRelaxTimeText") as? String ?? pointFirstRelaxTime.stringValue
            pointSecondRelaxTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointSecondRelaxTimeText") as? String ?? pointSecondRelaxTime.stringValue
            pointThirdRelaxTime.stringValue = confirmEveningRoutineTimeVcInfo.value(forKey: "pointThirdRelaxTimeText") as? String ?? pointThirdRelaxTime.stringValue
        }
        
    }
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 9)
        showOnboardingBellIcon(view: self.view, screen: "confirm-evening-routine-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    override func viewWillAppear() {
        var timeText = "At <TIME>:"
        if let confirmEveningRoutineTimeVcInfo = configjson.value(forKey: "confirmEveningRoutineTimeVcInfo") as? NSDictionary{
            timeText = confirmEveningRoutineTimeVcInfo.value(forKey: "timeText") as? String ?? timeText
        }
        
        lblRelaxModeTime.stringValue = timeText.replacingOccurrences(of: "<TIME>", with: askWorkTimeVcObj!.relaxModeTime)
        lblEveningRoutineTime.stringValue = timeText.replacingOccurrences(of: "<TIME>", with: askWorkTimeVcObj!.eveningRoutineTime)
        btnChangeThis.buttonColor = NSColor.white.cgColor
    }
    @IBAction func btnChangeThisClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "go-back-confirm-evening-routine", metadata: [:])
        mainViewControllerObj!.showAskWorkTimeVc()
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "continue-confirm-evening-routine", metadata: [:])
        mainViewControllerObj!.showTakeBreaksInfoVc()
    }
}

