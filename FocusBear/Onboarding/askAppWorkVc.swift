//
//  askAppWorkVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askAppWorkVc: NSViewController {

    @IBOutlet weak var checkBoxSecond: NSButton!
    @IBOutlet weak var checkBoxFirst: NSButton!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblCheckBoxSecond: NSTextField!
    @IBOutlet weak var lblCheckBoxFirst: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "What are your goals?"
        lblCheckBoxFirst.stringValue = "Help me develop healthy habits in the morning (e.g. meditate before starting work) and evening (e.g. have dinner with loved ones)"
        lblCheckBoxSecond.stringValue = "Help me stay focused during the work day"
        btnContinue.title = "Continue"
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            lblTitle.stringValue = askAppWorkVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblCheckBoxFirst.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxFirstText") as? String ?? lblCheckBoxFirst.stringValue
            lblCheckBoxSecond.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxSecondText") as? String ?? lblCheckBoxSecond.stringValue
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
    }
    
    override func viewWillAppear() {
        checkBoxFirst.state = .on
        checkBoxSecond.state = .on
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        if checkBoxFirst.state == .on && checkBoxSecond.state == .on{
            allApiObject.capturePosthog(event: "activate-all-features", metadata: [:])
        }else if checkBoxFirst.state == .on{
            allApiObject.capturePosthog(event: "activate-habits-only", metadata: [:])
        }else if checkBoxSecond.state == .on{
            allApiObject.capturePosthog(event: "activate-productivity-only", metadata: [:])
        }
        
        if checkBoxFirst.state == .off{
            isHabitsDisabled = true
        }else{
            isHabitsDisabled = false
        }
        if isHabitsDisabled{
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsHabitsDisabled)
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsIsHabitsDisabled)
        }
        
        addLog(text: "askAppWorkVc:- btnContinueClicked:isHabitsDisabled:- \(isHabitsDisabled)")

        
        
        mainViewControllerObj!.showAskWorkTimeVc()
    }
    @IBAction func checkBoxFirstClicked(_ sender: Any) {
        addLog(text: "askAppWorkVc:- checkBoxFirstClicked")
        if checkBoxFirst.state == .off && checkBoxSecond.state == .off{
            btnContinue.isEnabled = false
        }else{
            btnContinue.isEnabled = true
        }
    }
    @IBAction func checkBoxSecondClicked(_ sender: Any) {
        addLog(text: "askAppWorkVc:- checkBoxSecondClicked")
        if checkBoxFirst.state == .off && checkBoxSecond.state == .off{
            btnContinue.isEnabled = false
        }else{
            btnContinue.isEnabled = true
        }
    }
    
}
