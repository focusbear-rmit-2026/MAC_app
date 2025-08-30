//
//  askBreakTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class askBreakTimeVc: NSViewController {

    @IBOutlet weak var stepperMinutes: NSStepper!
    @IBOutlet weak var stepper: NSStepper!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var textFieldMinutes: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblMinutes: NSTextField!
    @IBOutlet weak var btnInfo: hoverInfoButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnInfo.isHidden = false
        lblTitle.stringValue = "Break reminders"
        lblQuestion.stringValue = "How frequently do you want to  take breaks?"
        lblDescription.stringValue = "(Optometrists recommend a 20 second break every 20 minutes)"
        btnContinue.title = "Continue"
        lblMinutes.stringValue = minutesText
        textFieldMinutes.delegate = self
        
        stepperMinutes.minValue = 1
        stepper.maxValue = 100000
        
        if let askBreakTimeVcInfo = configjson.value(forKey: "askBreakTimeVcInfo") as? NSDictionary{
            lblTitle.stringValue = askBreakTimeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = askBreakTimeVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblDescription.stringValue = askBreakTimeVcInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            btnContinue.title = askBreakTimeVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 11)
        showOnboardingBellIcon(view: self.view, screen: "ask-break-time-screen")
        textFieldMinutes.integerValue = defaultBreakDurationValue
        stepper.integerValue = defaultBreakDurationValue
        textFieldMinutes.setFocus()
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
//        allApiObject.capturePosthog(event: "ask-break-time-info-icon-clicked", metadata: [:])
        var msg = "To avoid screen headaches and neck strain, Focus Bear will encourage you to take breaks at regular intervals. We give you a 30 second warning so you can postpone the break if it's a bad time. We also detect if you're in a meeting and don't show breaks as that might lead to awkward screensharing moments otherwise!"
        if let askBreakTimeVcInfo = configjson.value(forKey: "askBreakTimeVcInfo") as? NSDictionary{
            msg = askBreakTimeVcInfo.value(forKey: "fullDescriptionText") as? String ?? msg
        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:300, autoCloseOnMouseExit: true)
        
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        UserDefaults.standard.set(textFieldMinutes.integerValue, forKey: kUserdefaultsBreakDurationValue)
        allApiObject.capturePosthog(event: "ask-break-time-continue-clicked", metadata: [:])
        appdelegate!.showOnbardingHabit()
    }
    @IBAction func stepperMinutesClicked(_ sender: Any) {
        textFieldMinutes.stringValue = "\(stepper.integerValue)"
        allApiObject.capturePosthog(event: "break-time-edited", metadata: [:])
    }
}

extension askBreakTimeVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField{
            if textField == self.textFieldMinutes{
                var count = textFieldMinutes.integerValue
                if count < 1{
                    count = 1
                    textFieldMinutes.stringValue = "\(count)"
                }else if count > 100000{
                    count = 100000
                }
                textFieldMinutes.stringValue = "\(count)"
                stepper.integerValue = count
                allApiObject.capturePosthog(event: "break-time-edited", metadata: [:])
            }
        }
    }
}
