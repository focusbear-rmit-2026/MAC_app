//
//  askAppWorkVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class additionalGoalsVc: NSViewController {// not in use

    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitleAdditionalGoals: NSTextField!
    @IBOutlet weak var textFieldAnythingElse: NSTextField!
    @IBOutlet weak var lblTitleAnythingElse: NSTextField!
    @IBOutlet weak var boxAnythingElse: NSBox!

    @IBOutlet weak var btnContinue: Button!

    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    @IBOutlet weak var lblCheckBoxSleepBetter: NSTextField!
    @IBOutlet weak var lblCheckBoxMeditateConsistently: NSTextField!
    
    @IBOutlet weak var lblCheckBoxImproveBalance: NSTextField!
    @IBOutlet weak var lblCheckBoxExerciseMore: NSTextField!
    
    
    @IBOutlet weak var checkBoxMeditateConsistently: NSButton!
    @IBOutlet weak var checkBoxSleepBetter: NSButton!
    @IBOutlet weak var checkBoxExerciseMore: NSButton!
    @IBOutlet weak var checkBoxImproveBalance: NSButton!
    
    @IBOutlet weak var lblGlad: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblSubTitle.stringValue = "Set your Goals and Preferences"
        lblQuestion.stringValue = "Are there other goals you want to achieve with Focus Bear?"
        lblGlad.stringValue = "Glad you're as passionate about building routines as we are!"
        lblTitleAdditionalGoals.stringValue = "Select all that apply"
        
        lblCheckBoxMeditateConsistently.stringValue = "Meditate consistently"
        lblCheckBoxSleepBetter.stringValue = "Sleep better"
        lblCheckBoxExerciseMore.stringValue = "Exercise more"
        lblCheckBoxImproveBalance.stringValue = "Improve work life balance"
        
        lblTitle.stringValue = "Focus Bear"
        

        btnContinue.title = "Continue"
        
        lblTitleAnythingElse.stringValue = "Anything else you hope Focus Bear can help with? (We'll try to take your feedback on board)"
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            lblTitle.stringValue = appName
            //lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue

            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            lblTitleAnythingElse.stringValue = askAppWorkVcInfo.value(forKey: "anythingElseText") as? String ?? lblTitleAnythingElse.stringValue
            lblCheckBoxMeditateConsistently.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxMeditateConsistentlyText") as? String ?? lblCheckBoxMeditateConsistently.stringValue
            lblCheckBoxSleepBetter.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxSleepBetterText") as? String ?? lblCheckBoxSleepBetter.stringValue
            lblCheckBoxExerciseMore.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxExerciseMoreText") as? String ?? lblCheckBoxExerciseMore.stringValue
            lblCheckBoxImproveBalance.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxImproveBalanceText") as? String ?? lblCheckBoxImproveBalance.stringValue
            //lblTitleAdditionalGoals.stringValue = askAppWorkVcInfo.value(forKey: "additionalGoalsText") as? String ?? lblTitleAdditionalGoals.stringValue
            lblSubTitle.stringValue = askAppWorkVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "titleAdditionalGoals") as? String ?? lblQuestion.stringValue
            lblGlad.stringValue = askAppWorkVcInfo.value(forKey: "gladText") as? String ?? lblGlad.stringValue
            lblTitleAdditionalGoals.stringValue = askAppWorkVcInfo.value(forKey: "selectGoalsText") as? String ?? lblTitleAdditionalGoals.stringValue
        }
        allApiObject.capturePosthog(event: "additional-goals-screen-shown", metadata: [:])
    }
    
    override func viewWillAppear() {
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }

    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        NotificationCenter.default.removeObserver(self)
        hideOnboardingBellIcon(view: self.view)
    }
    @objc func viewDidResize(){
        print("viewDidResize")
        if self.view.frame.height < 670{
            stackView.spacing = 12
        }else if self.view.frame.height < 770{
            stackView.spacing = 14
        }else{
            stackView.spacing = 18
        }
    }

    
    override func viewDidAppear() {
//        showOnboardingProgress(view: self.view, progress: 12)
    }

    @IBAction func btnContinueClicked(_ sender: Any) {
        
        var additionalGoals = [String]()
        
        if checkBoxMeditateConsistently.state == .on{
            additionalGoals.append(lblCheckBoxMeditateConsistently.stringValue)
        }
        
        if checkBoxSleepBetter.state == .on{
            additionalGoals.append(lblCheckBoxSleepBetter.stringValue)
        }
        
        if checkBoxExerciseMore.state == .on{
            additionalGoals.append(lblCheckBoxExerciseMore.stringValue)
        }
        
        if checkBoxImproveBalance.state == .on{
            additionalGoals.append(lblCheckBoxImproveBalance.stringValue)
        }
        
//        UserDefaults.standard.set(additionalGoals, forKey: kUserdefaultsAdditionalGoals)

        
        if !textFieldAnythingElse.stringValue.isEmpty{
            allApiObject.capturePosthog(event: "anything-else-goals-feedback", metadata: ["feedback":textFieldAnythingElse.stringValue])
        }
        
        mainViewControllerObj!.showInstalltHabitPacksVc()
        
    }

    
}
