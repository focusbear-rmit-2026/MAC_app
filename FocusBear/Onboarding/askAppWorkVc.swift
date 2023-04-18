//
//  askAppWorkVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askAppWorkVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
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
        
        lblTitle.stringValue = "Focus Bear"
        lblQuestion.stringValue = "What are your goals?"
        lblCheckBoxFirst.stringValue = "Help me develop healthy habits in the morning (e.g. meditate before starting work) and evening (e.g. have dinner with loved ones)"
        lblCheckBoxSecond.stringValue = "Help me stay focused during the work day"
        btnContinue.title = "Continue"
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            lblTitle.stringValue = appName
            lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblCheckBoxFirst.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxFirstText") as? String ?? lblCheckBoxFirst.stringValue
            lblCheckBoxSecond.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxSecondText") as? String ?? lblCheckBoxSecond.stringValue
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        allApiObject.capturePosthog(event: "goals-screen-shown", metadata: [:])
    }
    
    override func viewWillAppear() {
        checkBoxFirst.state = .off
        checkBoxSecond.state = .off
        btnContinue.isEnabled = false
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        btnContinue.isEnabled = false
        loader.startAnimation(self)
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
        var breaks_only = false
        if isHabitsDisabled{
            breaks_only = true
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsHabitsDisabled)
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsIsHabitsDisabled)
        }
        
        addLog(text: "askAppWorkVc:- btnContinueClicked:isHabitsDisabled:- \(isHabitsDisabled)")

        allApiObject.getHabitPacksInfo(breaks_only: breaks_only, completionHandler: {arrDic in
            DispatchQueue.main.async {
                self.btnContinue.isEnabled = true
                self.loader.stopAnimation(self)
            }
            if arrDic != nil{
                print(arrDic)
                DispatchQueue.main.async {
                    mainViewControllerObj!.showSelectHabitPacksVc()
                }
            }
        })
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
