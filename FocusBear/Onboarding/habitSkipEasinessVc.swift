//
//  habitSkipEasinessVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class habitSkipEasinessVc: NSViewController {
    
    @IBOutlet weak var radioBtnSecond: NSButton!
    @IBOutlet weak var radioBtnFirst: NSButton!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblRadioBtnSecond: NSTextField!
    @IBOutlet weak var lblRadioBtnFirst: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
      
        lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "How easy do you want it to be to skip your habits?"
        lblRadioBtnFirst.stringValue = "Really easy - I want to be able to skip habits/breaks in a hurry"
        lblRadioBtnSecond.stringValue = "Make it hard to skip - otherwise I'll end up skipping habits + breaks most of the time"
        btnContinue.title = "Continue"
        
        if let habitSkipEasinessVcInfo = configjson.value(forKey: "habitSkipEasinessVcInfo") as? NSDictionary{
            lblTitle.stringValue = habitSkipEasinessVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = habitSkipEasinessVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblRadioBtnFirst.stringValue = habitSkipEasinessVcInfo.value(forKey: "radioButtonFirstText") as? String ?? lblRadioBtnFirst.stringValue
            lblRadioBtnSecond.stringValue = habitSkipEasinessVcInfo.value(forKey: "radioButtonSecondText") as? String ?? lblRadioBtnSecond.stringValue
            btnContinue.title = habitSkipEasinessVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
    }
    
    override func viewWillAppear() {
        radioBtnFirst.state = .on
        radioBtnSecond.state = .off
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        var isHabitSkipEasy = false
        
        if radioBtnFirst.state == .on{
            isHabitSkipEasy = true
        }else if radioBtnSecond.state == .on{
            isHabitSkipEasy = false
        }
        
        UserDefaults.standard.set(isHabitSkipEasy, forKey: kUserdefaultsHabitSkipEasinessFromOnboarding)
        
        addLog(text: "habitSkip Onboarding view:- btnContinueClicked:isHabitSkipEasy:- \(isHabitSkipEasy)")
       // mainViewControllerObj!.showOnboardingBlockedUrlsVc()
    }
    
    @IBAction func radioBtnFirstClicked(_ sender: Any) {
        addLog(text: "habitSkip Onboarding view:- button Really easy to skip Clicked")
        radioBtnSecond.state = .off
    }
    
    @IBAction func radioBtnSecondClicked(_ sender: Any) {
        addLog(text: "habitSkip Onboarding view:- button Make it hard to skip Clicked")
        radioBtnFirst.state = .off
    }
}
